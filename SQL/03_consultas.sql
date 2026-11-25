-- =====================================================================
-- E6 - Consultas SQL | Tema 05 - Controle academico
-- Rodar depois de 01_ddl.sql e 02_carga.sql. Cada consulta traz a pergunta acima e o resultado abaixo.
-- Os resultados foram apurados com a carga do E5; a formatacao de decimais pode variar no MySQL.
-- Q1 a Q5 sao as perguntas do enunciado; Q6 a Q10 sao propostas pelo grupo.
-- =====================================================================
USE controle_academico;

-- Q1 - Quem pode se matricular numa disciplina
-- Pergunta: Quais alunos podem se matricular na disciplina IA (pré-requisitos ED e MAT), isto é, já foram aprovados em todos os pré-requisitos dela (e ainda não foram aprovados nem estão cursando a própria IA)?
SELECT a.ra, p.nome AS aluno, c.nome AS curso, mc.ano_inicio AS matriz
FROM aluno a
JOIN pessoa p ON p.id_pessoa = a.id_aluno
JOIN matriz_curricular mc ON mc.id_matriz = a.id_matriz
JOIN curso c ON c.id_curso = mc.id_curso
JOIN matriz_disciplina md ON md.id_matriz = a.id_matriz
JOIN disciplina d ON d.id_disciplina = md.id_disciplina AND d.codigo = 'IA'
WHERE NOT EXISTS (
        SELECT 1 FROM pre_requisito pr
        WHERE pr.id_disciplina = d.id_disciplina
          AND NOT EXISTS (SELECT 1 FROM vw_resultado_matricula r
                          WHERE r.id_aluno = a.id_aluno
                            AND r.id_disciplina = pr.id_disciplina_requisito
                            AND r.resultado = 'APROVADO'))
  AND NOT EXISTS (
        SELECT 1 FROM vw_resultado_matricula r2
        WHERE r2.id_aluno = a.id_aluno
          AND r2.id_disciplina = d.id_disciplina
          AND r2.resultado IN ('APROVADO', 'EM CURSO'))
ORDER BY p.nome;
-- Resultado obtido:
--   ra         | aluno           | curso                                 | matriz
--   -----------+-----------------+---------------------------------------+-------
--   RA20250022 | Amanda Freitas  | Sistemas de Informação                | 2022  
--   RA20250016 | Camila Souza    | Análise e Desenvolvimento de Sistemas | 2025  
--   RA20250021 | Felipe Cardoso  | Sistemas de Informação                | 2022  
--   RA20250020 | Isabela Ribeiro | Sistemas de Informação                | 2022  
--   RA20250015 | Rafael Lima     | Análise e Desenvolvimento de Sistemas | 2025  
--   RA20250017 | Thiago Barbosa  | Análise e Desenvolvimento de Sistemas | 2025  
--   (6 linhas)

-- Q2 - Taxa de reprovação por disciplina no semestre
-- Pergunta: Qual a taxa de reprovação por disciplina no semestre 2026/1 (último com diário fechado)? Trancamentos ficam de fora.
SELECT d.codigo, d.nome AS disciplina,
       COUNT(*) AS matriculas_validas,
       SUM(CASE WHEN r.resultado LIKE 'REPROVADO%' THEN 1 ELSE 0 END) AS reprovados,
       ROUND(100.0 * SUM(CASE WHEN r.resultado LIKE 'REPROVADO%' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_reprovacao_pct
FROM vw_resultado_matricula r
JOIN disciplina d ON d.id_disciplina = r.id_disciplina
JOIN periodo_letivo p ON p.id_periodo = r.id_periodo
WHERE p.ano = 2026 AND p.semestre = 1
  AND r.resultado IN ('APROVADO', 'REPROVADO POR NOTA', 'REPROVADO POR FALTA')
GROUP BY d.id_disciplina, d.codigo, d.nome
ORDER BY taxa_reprovacao_pct DESC, d.codigo;
-- Resultado obtido:
--   codigo | disciplina                         | matriculas_validas | reprovados | taxa_reprovacao_pct
--   -------+------------------------------------+--------------------+------------+--------------------
--   MAT    | Matemática Discreta                | 2                  | 2          | 100.0              
--   BD2    | Banco de Dados Avançado            | 6                  | 2          | 33.3               
--   ALG    | Algoritmos e Lógica de Programação | 1                  | 0          | 0.0                
--   ED     | Estruturas de Dados                | 2                  | 0          | 0.0                
--   ENGS   | Engenharia de Software             | 2                  | 0          | 0.0                
--   SO     | Sistemas Operacionais              | 5                  | 0          | 0.0                
--   WEB    | Desenvolvimento Web                | 5                  | 0          | 0.0                
--   (7 linhas)

-- Q3 - Disciplinas da matriz sem turma no semestre
-- Pergunta: Quais disciplinas de cada matriz não tiveram turma aberta no semestre 2026/2?
SELECT c.nome AS curso, mc.ano_inicio AS matriz, d.codigo, d.nome AS disciplina, md.semestre_sugerido
FROM matriz_curricular mc
JOIN curso c ON c.id_curso = mc.id_curso
JOIN matriz_disciplina md ON md.id_matriz = mc.id_matriz
JOIN disciplina d ON d.id_disciplina = md.id_disciplina
WHERE NOT EXISTS (SELECT 1 FROM turma t
                  JOIN periodo_letivo p ON p.id_periodo = t.id_periodo
                  WHERE t.id_disciplina = md.id_disciplina
                    AND p.ano = 2026 AND p.semestre = 2)
ORDER BY c.nome, mc.ano_inicio, md.semestre_sugerido, d.codigo;
-- Resultado obtido:
--   curso                                 | matriz | codigo | disciplina                         | semestre_sugerido
--   --------------------------------------+--------+--------+------------------------------------+------------------
--   Análise e Desenvolvimento de Sistemas | 2019   | ING    | Inglês Técnico                     | 1                
--   Análise e Desenvolvimento de Sistemas | 2019   | MAT    | Matemática Discreta                | 1                
--   Análise e Desenvolvimento de Sistemas | 2019   | POO2   | Programação Orientada a Objetos II | 3                
--   Análise e Desenvolvimento de Sistemas | 2025   | MAT    | Matemática Discreta                | 1                
--   Análise e Desenvolvimento de Sistemas | 2025   | ING    | Inglês Técnico                     | 2                
--   Análise e Desenvolvimento de Sistemas | 2025   | IA     | Inteligência Artificial            | 5                
--   Análise e Desenvolvimento de Sistemas | 2025   | PROJ   | Projeto Integrador                 | 6                
--   Sistemas de Informação                | 2022   | ING    | Inglês Técnico                     | 1                
--   Sistemas de Informação                | 2022   | MAT    | Matemática Discreta                | 1                
--   Sistemas de Informação                | 2022   | IA     | Inteligência Artificial            | 6                
--   Sistemas de Informação                | 2022   | SEG    | Segurança da Informação            | 6                
--   (11 linhas)

-- Q4 - Carga horária cursada por aluno
-- Pergunta: Qual a carga horária total já cursada (disciplinas aprovadas, pela carga da matriz de cada aluno)?
SELECT a.ra, p.nome AS aluno,
       COALESCE(SUM(md.carga_horaria), 0) AS carga_horaria_cursada
FROM aluno a
JOIN pessoa p ON p.id_pessoa = a.id_aluno
LEFT JOIN vw_resultado_matricula r ON r.id_aluno = a.id_aluno AND r.resultado = 'APROVADO'
LEFT JOIN matriz_disciplina md ON md.id_matriz = a.id_matriz AND md.id_disciplina = r.id_disciplina
GROUP BY a.id_aluno, a.ra, p.nome
ORDER BY carga_horaria_cursada DESC, p.nome;
-- Resultado obtido:
--   ra         | aluno               | carga_horaria_cursada
--   -----------+---------------------+----------------------
--   RA20240014 | Beatriz Rocha       | 660                  
--   RA20240012 | Mariana Costa       | 640                  
--   RA20250015 | Rafael Lima         | 620                  
--   RA20250021 | Felipe Cardoso      | 600                  
--   RA20250020 | Isabela Ribeiro     | 600                  
--   RA20240011 | Lucas Pereira       | 580                  
--   RA20250016 | Camila Souza        | 480                  
--   RA20250022 | Amanda Freitas      | 440                  
--   RA20250018 | Larissa Mendes      | 420                  
--   RA20250017 | Thiago Barbosa      | 340                  
--   RA20240013 | Gabriel Santos      | 320                  
--   RA20250019 | Pedro Henrique Dias | 120                  
--   RA20260004 | Ricardo Almeida     | 0                    
--   (13 linhas)

-- Q5 - Professores com mais de quatro turmas
-- Pergunta: Quais professores estão com mais de quatro turmas no semestre 2026/2 (titular ou colaborador)?
SELECT p.nome AS professor, COUNT(*) AS turmas
FROM turma_professor tp
JOIN professor pr ON pr.id_professor = tp.id_professor
JOIN pessoa p ON p.id_pessoa = pr.id_professor
JOIN turma t ON t.id_turma = tp.id_turma
JOIN periodo_letivo pl ON pl.id_periodo = t.id_periodo
WHERE pl.ano = 2026 AND pl.semestre = 2
GROUP BY pr.id_professor, p.nome
HAVING COUNT(*) > 4
ORDER BY turmas DESC, p.nome;
-- Resultado obtido:
--   professor      | turmas
--   ---------------+-------
--   Helena Martins | 5     
--   (1 linha)

-- Q6 - Alunos em risco nas turmas em curso (pergunta do grupo)
-- Pergunta: Quais alunos estão, hoje, com média parcial abaixo de 6,0 ou frequência abaixo de 75% em turmas de 2026/2?
SELECT p.nome AS aluno, d.codigo AS disciplina, r.media AS media_parcial, r.frequencia_pct
FROM vw_resultado_matricula r
JOIN pessoa p ON p.id_pessoa = r.id_aluno
JOIN disciplina d ON d.id_disciplina = r.id_disciplina
JOIN periodo_letivo pl ON pl.id_periodo = r.id_periodo
WHERE r.resultado = 'EM CURSO' AND pl.ano = 2026 AND pl.semestre = 2
  AND (COALESCE(r.media, 0) < 6 OR r.frequencia_pct < 75)
ORDER BY p.nome, d.codigo;
-- Resultado obtido:
--   aluno               | disciplina | media_parcial | frequencia_pct
--   --------------------+------------+---------------+---------------
--   Camila Souza        | POO1       | 5.07          | 87.5          
--   Felipe Cardoso      | REDES      | 4.39          | 87.5          
--   Lucas Pereira       | BD2        | 6.36          | 50.0          
--   Pedro Henrique Dias | POO1       | 3.87          | 100.0         
--   Rafael Lima         | BD2        | 4.27          | 100.0         
--   Rafael Lima         | REDES      | 6.64          | 62.5          
--   Thiago Barbosa      | SO         | 4.67          | 62.5          
--   (7 linhas)

-- Q7 - Pré-requisitos diretos de cada disciplina (pergunta do grupo)
-- Pergunta: Quais são os pré-requisitos diretos de cada disciplina, incluindo as que não exigem nenhum?
SELECT d.codigo, d.nome AS disciplina,
       COALESCE(GROUP_CONCAT(req.codigo ORDER BY req.codigo), '(nenhum)') AS pre_requisitos
FROM disciplina d
LEFT JOIN pre_requisito pr ON pr.id_disciplina = d.id_disciplina
LEFT JOIN disciplina req ON req.id_disciplina = pr.id_disciplina_requisito
GROUP BY d.id_disciplina, d.codigo, d.nome
ORDER BY d.id_disciplina;
-- Resultado obtido:
--   codigo | disciplina                         | pre_requisitos
--   -------+------------------------------------+---------------
--   ALG    | Algoritmos e Lógica de Programação | (nenhum)      
--   MAT    | Matemática Discreta                | (nenhum)      
--   ING    | Inglês Técnico                     | (nenhum)      
--   POO1   | Programação Orientada a Objetos I  | ALG           
--   POO2   | Programação Orientada a Objetos II | POO1          
--   ED     | Estruturas de Dados                | ALG,MAT       
--   BD1    | Modelagem de Banco de Dados        | ALG           
--   BD2    | Banco de Dados Avançado            | BD1,ED        
--   ENGS   | Engenharia de Software             | BD1,POO1      
--   WEB    | Desenvolvimento Web                | BD1,POO1      
--   SO     | Sistemas Operacionais              | ED            
--   REDES  | Redes de Computadores              | SO            
--   SEG    | Segurança da Informação            | ED,REDES      
--   IA     | Inteligência Artificial            | ED,MAT        
--   PROJ   | Projeto Integrador                 | BD2,ENGS,WEB  
--   (15 linhas)

-- Q8 - O que mudou entre as matrizes de ADS (pergunta do grupo)
-- Pergunta: Quais disciplinas comuns às matrizes 2019 e 2025 de Análise e Desenvolvimento de Sistemas mudaram de semestre ou de carga horária?
SELECT d.codigo, d.nome AS disciplina,
       a.semestre_sugerido AS sem_2019, b.semestre_sugerido AS sem_2025,
       a.carga_horaria AS ch_2019, b.carga_horaria AS ch_2025
FROM matriz_disciplina a
JOIN matriz_curricular ma ON ma.id_matriz = a.id_matriz AND ma.id_curso = 1 AND ma.ano_inicio = 2019
JOIN matriz_disciplina b ON b.id_disciplina = a.id_disciplina
JOIN matriz_curricular mb ON mb.id_matriz = b.id_matriz AND mb.id_curso = 1 AND mb.ano_inicio = 2025
JOIN disciplina d ON d.id_disciplina = a.id_disciplina
WHERE a.semestre_sugerido <> b.semestre_sugerido OR a.carga_horaria <> b.carga_horaria
ORDER BY d.codigo;
-- Resultado obtido:
--   codigo | disciplina                  | sem_2019 | sem_2025 | ch_2019 | ch_2025
--   -------+-----------------------------+----------+----------+---------+--------
--   BD1    | Modelagem de Banco de Dados | 2        | 3        | 60      | 80     
--   ED     | Estruturas de Dados         | 3        | 2        | 60      | 80     
--   ENGS   | Engenharia de Software      | 4        | 3        | 60      | 60     
--   ING    | Inglês Técnico              | 1        | 2        | 40      | 40     
--   SO     | Sistemas Operacionais       | 5        | 4        | 60      | 60     
--   WEB    | Desenvolvimento Web         | 5        | 4        | 60      | 80     
--   (6 linhas)

-- Q9 - Turmas com coadministração (pergunta do grupo)
-- Pergunta: Quais turmas de 2026/2 são conduzidas por mais de um professor, e quem são eles?
SELECT d.codigo AS disciplina, t.codigo AS turma, COUNT(*) AS professores,
       GROUP_CONCAT(p.nome ORDER BY p.nome) AS docentes
FROM turma t
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
JOIN periodo_letivo pl ON pl.id_periodo = t.id_periodo
JOIN turma_professor tp ON tp.id_turma = t.id_turma
JOIN pessoa p ON p.id_pessoa = tp.id_professor
WHERE pl.ano = 2026 AND pl.semestre = 2
GROUP BY t.id_turma, d.codigo, t.codigo
HAVING COUNT(*) > 1
ORDER BY d.codigo;
-- Resultado obtido:
--   disciplina | turma | professores | docentes                                           
--   -----------+-------+-------------+----------------------------------------------------
--   BD2        | A     | 2           | Carlos Eduardo Prado,Roberto Siqueira              
--   ED         | A     | 2           | Carlos Eduardo Prado,Helena Martins                
--   ENGS       | A     | 2           | Helena Martins,Patrícia Nogueira                   
--   SO         | A     | 2           | André Camargo,Fernanda Lopes                       
--   WEB        | A     | 3           | Carlos Eduardo Prado,Helena Martins,Sandra Oliveira
--   (5 linhas)

-- Q10 - Pessoas por papel (pergunta do grupo)
-- Pergunta: Quantas pessoas são só aluno, só professor, aluno e professor ao mesmo tempo, ou não têm vínculo nenhum?
SELECT CASE WHEN a.id_aluno IS NOT NULL AND pr.id_professor IS NOT NULL THEN 'ALUNO E PROFESSOR'
            WHEN a.id_aluno IS NOT NULL THEN 'APENAS ALUNO'
            WHEN pr.id_professor IS NOT NULL THEN 'APENAS PROFESSOR'
            ELSE 'SEM VINCULO' END AS papel,
       COUNT(*) AS pessoas
FROM pessoa p
LEFT JOIN aluno a ON a.id_aluno = p.id_pessoa
LEFT JOIN professor pr ON pr.id_professor = p.id_pessoa
GROUP BY papel
ORDER BY pessoas DESC;
-- Resultado obtido:
--   papel             | pessoas
--   ------------------+--------
--   APENAS ALUNO      | 12     
--   APENAS PROFESSOR  | 9      
--   SEM VINCULO       | 1      
--   ALUNO E PROFESSOR | 1      
--   (4 linhas)
