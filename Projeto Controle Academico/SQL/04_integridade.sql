-- =====================================================================
-- E7 - Demonstracao de integridade | Tema 05 - Controle academico
-- Rodar depois de 01_ddl.sql e 02_carga.sql. Os tres comandos DEVEM falhar.
-- Cada um foi conferido num banco de teste: nenhum alterou dados.
--
-- ATENCAO: as mensagens abaixo seguem o formato do MySQL 8.0.19 ou superior.
-- Como o enunciado pede a mensagem EXATA do SGBD, rode os comandos no seu
-- servidor e confira/cole a mensagem real ao lado (o numero da versao pode
-- mudar detalhes, como 'disciplina.PRIMARY' x 'PRIMARY').
-- =====================================================================
USE controle_academico;

-- 1) INTEGRIDADE REFERENCIAL: matricula em turma que nao existe (id_turma = 999)
INSERT INTO matricula (id_aluno, id_turma, data_matricula, status)
VALUES (11, 999, '2026-08-01', 'ATIVA');
-- Mensagem esperada:
-- ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
-- (`controle_academico`.`matricula`, CONSTRAINT `fk_matricula_turma`
--  FOREIGN KEY (`id_turma`) REFERENCES `turma` (`id_turma`))

-- 2) CHAVE: disciplina com id_disciplina = 1, que ja existe (chave primaria duplicada)
INSERT INTO disciplina (id_disciplina, codigo, nome)
VALUES (1, 'XYZ', 'Disciplina duplicada');
-- Mensagem esperada:
-- ERROR 1062 (23000): Duplicate entry '1' for key 'disciplina.PRIMARY'

-- 3) DOMINIO: nota fora do intervalo de 0 a 10 (RN16)
UPDATE nota
   SET valor = 11
 WHERE id_aluno = 11 AND id_turma = 1 AND id_avaliacao = 1;
-- Mensagem esperada:
-- ERROR 3819 (HY000): Check constraint 'ck_nota_valor' is violated.
