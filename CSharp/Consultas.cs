namespace AcademicoApp;

public record Consulta(string Titulo, string Pergunta, string Sql, (string Nome, string Padrao)[] Parametros);

// Catalogo gerado a partir de 03_consultas.sql: os mesmos SQLs, com @parametros.
public static class Catalogo
{
    public static readonly Consulta[] Todas =
    {
        new("Q1 - Quem pode se matricular numa disciplina",
            "Quais alunos podem se matricular na disciplina IA (pré-requisitos ED e MAT), isto é, já foram aprovados em todos os pré-requisitos dela (e ainda não foram aprovados nem estão cursando a própria IA)?",
            @"SELECT a.ra, p.nome AS aluno, c.nome AS curso, mc.ano_inicio AS matriz
FROM aluno a
JOIN pessoa p ON p.id_pessoa = a.id_aluno
JOIN matriz_curricular mc ON mc.id_matriz = a.id_matriz
JOIN curso c ON c.id_curso = mc.id_curso
JOIN matriz_disciplina md ON md.id_matriz = a.id_matriz
JOIN disciplina d ON d.id_disciplina = md.id_disciplina AND d.codigo = @codigo
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
ORDER BY p.nome;",
            new (string, string)[] { ("codigo", "IA") }),
        new("Q2 - Taxa de reprovação por disciplina no semestre",
            "Qual a taxa de reprovação por disciplina no semestre 2026/1 (último com diário fechado)? Trancamentos ficam de fora.",
            @"SELECT d.codigo, d.nome AS disciplina,
       COUNT(*) AS matriculas_validas,
       SUM(CASE WHEN r.resultado LIKE 'REPROVADO%' THEN 1 ELSE 0 END) AS reprovados,
       ROUND(100.0 * SUM(CASE WHEN r.resultado LIKE 'REPROVADO%' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_reprovacao_pct
FROM vw_resultado_matricula r
JOIN disciplina d ON d.id_disciplina = r.id_disciplina
JOIN periodo_letivo p ON p.id_periodo = r.id_periodo
WHERE p.ano = @ano AND p.semestre = @semestre
  AND r.resultado IN ('APROVADO', 'REPROVADO POR NOTA', 'REPROVADO POR FALTA')
GROUP BY d.id_disciplina, d.codigo, d.nome
ORDER BY taxa_reprovacao_pct DESC, d.codigo;",
            new (string, string)[] { ("ano", "2026"), ("semestre", "1") }),
        new("Q3 - Disciplinas da matriz sem turma no semestre",
            "Quais disciplinas de cada matriz não tiveram turma aberta no semestre 2026/2?",
            @"SELECT c.nome AS curso, mc.ano_inicio AS matriz, d.codigo, d.nome AS disciplina, md.semestre_sugerido
FROM matriz_curricular mc
JOIN curso c ON c.id_curso = mc.id_curso
JOIN matriz_disciplina md ON md.id_matriz = mc.id_matriz
JOIN disciplina d ON d.id_disciplina = md.id_disciplina
WHERE NOT EXISTS (SELECT 1 FROM turma t
                  JOIN periodo_letivo p ON p.id_periodo = t.id_periodo
                  WHERE t.id_disciplina = md.id_disciplina
                    AND p.ano = @ano AND p.semestre = @semestre)
ORDER BY c.nome, mc.ano_inicio, md.semestre_sugerido, d.codigo;",
            new (string, string)[] { ("ano", "2026"), ("semestre", "2") }),
        new("Q4 - Carga horária cursada por aluno",
            "Qual a carga horária total já cursada (disciplinas aprovadas, pela carga da matriz de cada aluno)?",
            @"SELECT a.ra, p.nome AS aluno,
       COALESCE(SUM(md.carga_horaria), 0) AS carga_horaria_cursada
FROM aluno a
JOIN pessoa p ON p.id_pessoa = a.id_aluno
LEFT JOIN vw_resultado_matricula r ON r.id_aluno = a.id_aluno AND r.resultado = 'APROVADO'
LEFT JOIN matriz_disciplina md ON md.id_matriz = a.id_matriz AND md.id_disciplina = r.id_disciplina
GROUP BY a.id_aluno, a.ra, p.nome
ORDER BY carga_horaria_cursada DESC, p.nome;",
            new (string, string)[] {  }),
        new("Q5 - Professores com mais de quatro turmas",
            "Quais professores estão com mais de quatro turmas no semestre 2026/2 (titular ou colaborador)?",
            @"SELECT p.nome AS professor, COUNT(*) AS turmas
FROM turma_professor tp
JOIN professor pr ON pr.id_professor = tp.id_professor
JOIN pessoa p ON p.id_pessoa = pr.id_professor
JOIN turma t ON t.id_turma = tp.id_turma
JOIN periodo_letivo pl ON pl.id_periodo = t.id_periodo
WHERE pl.ano = @ano AND pl.semestre = @semestre
GROUP BY pr.id_professor, p.nome
HAVING COUNT(*) > @min
ORDER BY turmas DESC, p.nome;",
            new (string, string)[] { ("ano", "2026"), ("semestre", "2"), ("min", "4") }),
        new("Q6 - Alunos em risco nas turmas em curso (pergunta do grupo)",
            "Quais alunos estão, hoje, com média parcial abaixo de 6,0 ou frequência abaixo de 75% em turmas de 2026/2?",
            @"SELECT p.nome AS aluno, d.codigo AS disciplina, r.media AS media_parcial, r.frequencia_pct
FROM vw_resultado_matricula r
JOIN pessoa p ON p.id_pessoa = r.id_aluno
JOIN disciplina d ON d.id_disciplina = r.id_disciplina
JOIN periodo_letivo pl ON pl.id_periodo = r.id_periodo
WHERE r.resultado = 'EM CURSO' AND pl.ano = @ano AND pl.semestre = @semestre
  AND (COALESCE(r.media, 0) < 6 OR r.frequencia_pct < 75)
ORDER BY p.nome, d.codigo;",
            new (string, string)[] { ("ano", "2026"), ("semestre", "2") }),
        new("Q7 - Pré-requisitos diretos de cada disciplina (pergunta do grupo)",
            "Quais são os pré-requisitos diretos de cada disciplina, incluindo as que não exigem nenhum?",
            @"SELECT d.codigo, d.nome AS disciplina,
       COALESCE(GROUP_CONCAT(req.codigo ORDER BY req.codigo), '(nenhum)') AS pre_requisitos
FROM disciplina d
LEFT JOIN pre_requisito pr ON pr.id_disciplina = d.id_disciplina
LEFT JOIN disciplina req ON req.id_disciplina = pr.id_disciplina_requisito
GROUP BY d.id_disciplina, d.codigo, d.nome
ORDER BY d.id_disciplina;",
            new (string, string)[] {  }),
        new("Q8 - O que mudou entre as matrizes de ADS (pergunta do grupo)",
            "Quais disciplinas comuns às matrizes 2019 e 2025 de Análise e Desenvolvimento de Sistemas mudaram de semestre ou de carga horária?",
            @"SELECT d.codigo, d.nome AS disciplina,
       a.semestre_sugerido AS sem_2019, b.semestre_sugerido AS sem_2025,
       a.carga_horaria AS ch_2019, b.carga_horaria AS ch_2025
FROM matriz_disciplina a
JOIN matriz_curricular ma ON ma.id_matriz = a.id_matriz AND ma.id_curso = 1 AND ma.ano_inicio = 2019
JOIN matriz_disciplina b ON b.id_disciplina = a.id_disciplina
JOIN matriz_curricular mb ON mb.id_matriz = b.id_matriz AND mb.id_curso = 1 AND mb.ano_inicio = 2025
JOIN disciplina d ON d.id_disciplina = a.id_disciplina
WHERE a.semestre_sugerido <> b.semestre_sugerido OR a.carga_horaria <> b.carga_horaria
ORDER BY d.codigo;",
            new (string, string)[] {  }),
        new("Q9 - Turmas com coadministração (pergunta do grupo)",
            "Quais turmas de 2026/2 são conduzidas por mais de um professor, e quem são eles?",
            @"SELECT d.codigo AS disciplina, t.codigo AS turma, COUNT(*) AS professores,
       GROUP_CONCAT(p.nome ORDER BY p.nome) AS docentes
FROM turma t
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
JOIN periodo_letivo pl ON pl.id_periodo = t.id_periodo
JOIN turma_professor tp ON tp.id_turma = t.id_turma
JOIN pessoa p ON p.id_pessoa = tp.id_professor
WHERE pl.ano = @ano AND pl.semestre = @semestre
GROUP BY t.id_turma, d.codigo, t.codigo
HAVING COUNT(*) > 1
ORDER BY d.codigo;",
            new (string, string)[] { ("ano", "2026"), ("semestre", "2") }),
        new("Q10 - Pessoas por papel (pergunta do grupo)",
            "Quantas pessoas são só aluno, só professor, aluno e professor ao mesmo tempo, ou não têm vínculo nenhum?",
            @"SELECT CASE WHEN a.id_aluno IS NOT NULL AND pr.id_professor IS NOT NULL THEN 'ALUNO E PROFESSOR'
            WHEN a.id_aluno IS NOT NULL THEN 'APENAS ALUNO'
            WHEN pr.id_professor IS NOT NULL THEN 'APENAS PROFESSOR'
            ELSE 'SEM VINCULO' END AS papel,
       COUNT(*) AS pessoas
FROM pessoa p
LEFT JOIN aluno a ON a.id_aluno = p.id_pessoa
LEFT JOIN professor pr ON pr.id_professor = p.id_pessoa
GROUP BY papel
ORDER BY pessoas DESC;",
            new (string, string)[] {  }),
    };
}
