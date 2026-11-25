-- =====================================================================
-- E4 - Script DDL | Tema 05 - Controle academico com pre-requisitos
-- SGBD: MySQL 8.0.16 ou superior (CHECK so e aplicado a partir dessa versao)
-- Roda do zero: o banco e recriado a cada execucao.
-- As siglas RNxx referem-se as regras de negocio numeradas no E1.
-- =====================================================================
DROP DATABASE IF EXISTS controle_academico;
CREATE DATABASE controle_academico CHARACTER SET utf8mb4;
USE controle_academico;

-- ---------------------------------------------------------------------
-- Pessoa e especializacoes (generalizacao parcial / compartilhada)
-- ---------------------------------------------------------------------
CREATE TABLE pessoa (
    id_pessoa        INT          NOT NULL AUTO_INCREMENT,
    nome             VARCHAR(100) NOT NULL,
    cpf              CHAR(11)     NOT NULL,
    email            VARCHAR(100) NOT NULL,
    data_nascimento  DATE         NOT NULL,          -- idade e calculada (RN01)
    logradouro       VARCHAR(100),                   -- endereco composto vira colunas
    numero           VARCHAR(10),
    bairro           VARCHAR(60),
    cidade           VARCHAR(60),
    uf               CHAR(2),
    CONSTRAINT pk_pessoa       PRIMARY KEY (id_pessoa),
    CONSTRAINT uq_pessoa_cpf   UNIQUE (cpf),
    CONSTRAINT uq_pessoa_email UNIQUE (email),
    CONSTRAINT ck_pessoa_cpf   CHECK (LENGTH(cpf) = 11)
);

-- Atributo multivalorado: telefone
CREATE TABLE pessoa_telefone (
    id_pessoa  INT         NOT NULL,
    telefone   VARCHAR(15) NOT NULL,
    CONSTRAINT pk_pessoa_telefone PRIMARY KEY (id_pessoa, telefone),
    CONSTRAINT fk_telefone_pessoa FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa)
);

-- ---------------------------------------------------------------------
-- Curso e matriz curricular (versionada)
-- ---------------------------------------------------------------------
CREATE TABLE curso (
    id_curso          INT         NOT NULL AUTO_INCREMENT,
    nome              VARCHAR(80) NOT NULL,
    grau              VARCHAR(15) NOT NULL,
    duracao_semestres TINYINT     NOT NULL,
    CONSTRAINT pk_curso      PRIMARY KEY (id_curso),
    CONSTRAINT uq_curso_nome UNIQUE (nome),
    CONSTRAINT ck_curso_grau CHECK (grau IN ('TECNOLOGO', 'BACHARELADO', 'LICENCIATURA')),
    CONSTRAINT ck_curso_dur  CHECK (duracao_semestres > 0)
);

CREATE TABLE matriz_curricular (
    id_matriz  INT      NOT NULL AUTO_INCREMENT,
    id_curso   INT      NOT NULL,
    ano_inicio SMALLINT NOT NULL,
    ano_fim    SMALLINT NULL,                         -- NULL = matriz ainda vigente
    CONSTRAINT pk_matriz       PRIMARY KEY (id_matriz),
    CONSTRAINT uq_matriz_curso_ano UNIQUE (id_curso, ano_inicio),
    CONSTRAINT fk_matriz_curso FOREIGN KEY (id_curso) REFERENCES curso (id_curso),
    CONSTRAINT ck_matriz_anos  CHECK (ano_fim IS NULL OR ano_fim >= ano_inicio)
);

-- ---------------------------------------------------------------------
-- Disciplina, pre-requisito (auto relacionamento N:N) e matriz x disciplina
-- ---------------------------------------------------------------------
CREATE TABLE disciplina (
    id_disciplina INT          NOT NULL AUTO_INCREMENT,
    codigo        VARCHAR(10)  NOT NULL,
    nome          VARCHAR(80)  NOT NULL,
    ementa        VARCHAR(255),
    CONSTRAINT pk_disciplina        PRIMARY KEY (id_disciplina),
    CONSTRAINT uq_disciplina_codigo UNIQUE (codigo)
);

CREATE TABLE pre_requisito (
    id_disciplina           INT NOT NULL,   -- a disciplina que exige
    id_disciplina_requisito INT NOT NULL,   -- a disciplina exigida
    CONSTRAINT pk_pre_requisito PRIMARY KEY (id_disciplina, id_disciplina_requisito),
    CONSTRAINT fk_prereq_disc   FOREIGN KEY (id_disciplina)           REFERENCES disciplina (id_disciplina),
    CONSTRAINT fk_prereq_req    FOREIGN KEY (id_disciplina_requisito) REFERENCES disciplina (id_disciplina),
    CONSTRAINT ck_prereq_difere CHECK (id_disciplina <> id_disciplina_requisito)
);

CREATE TABLE matriz_disciplina (
    id_matriz        INT      NOT NULL,
    id_disciplina    INT      NOT NULL,
    semestre_sugerido TINYINT NOT NULL,
    carga_horaria    SMALLINT NOT NULL,             -- depende da matriz E da disciplina
    obrigatoria      BOOLEAN  NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_matriz_disciplina PRIMARY KEY (id_matriz, id_disciplina),
    CONSTRAINT fk_md_matriz     FOREIGN KEY (id_matriz)     REFERENCES matriz_curricular (id_matriz),
    CONSTRAINT fk_md_disciplina FOREIGN KEY (id_disciplina) REFERENCES disciplina (id_disciplina),
    CONSTRAINT ck_md_semestre   CHECK (semestre_sugerido BETWEEN 1 AND 12),
    CONSTRAINT ck_md_carga      CHECK (carga_horaria > 0)
);

-- ---------------------------------------------------------------------
-- Aluno e professor (PK = FK para pessoa)
-- ---------------------------------------------------------------------
CREATE TABLE aluno (
    id_aluno      INT         NOT NULL,
    ra            VARCHAR(12) NOT NULL,
    data_ingresso DATE        NOT NULL,
    id_matriz     INT         NOT NULL,             -- matriz de ingresso; o aluno nao migra (RN05)
    CONSTRAINT pk_aluno        PRIMARY KEY (id_aluno),
    CONSTRAINT uq_aluno_ra     UNIQUE (ra),
    CONSTRAINT fk_aluno_pessoa FOREIGN KEY (id_aluno)  REFERENCES pessoa (id_pessoa),
    CONSTRAINT fk_aluno_matriz FOREIGN KEY (id_matriz) REFERENCES matriz_curricular (id_matriz)
);

CREATE TABLE professor (
    id_professor INT         NOT NULL,
    titulacao    VARCHAR(15) NOT NULL,
    regime       VARCHAR(3)  NOT NULL,
    CONSTRAINT pk_professor        PRIMARY KEY (id_professor),
    CONSTRAINT fk_professor_pessoa FOREIGN KEY (id_professor) REFERENCES pessoa (id_pessoa),
    CONSTRAINT ck_professor_tit    CHECK (titulacao IN ('ESPECIALISTA', 'MESTRE', 'DOUTOR')),
    CONSTRAINT ck_professor_reg    CHECK (regime IN ('20H', '40H', 'DE'))
);

-- ---------------------------------------------------------------------
-- Periodo letivo, turma e coadministracao
-- ---------------------------------------------------------------------
CREATE TABLE periodo_letivo (
    id_periodo  INT      NOT NULL AUTO_INCREMENT,
    ano         SMALLINT NOT NULL,
    semestre    TINYINT  NOT NULL,
    data_inicio DATE     NOT NULL,
    data_fim    DATE     NOT NULL,
    CONSTRAINT pk_periodo         PRIMARY KEY (id_periodo),
    CONSTRAINT uq_periodo_ano_sem UNIQUE (ano, semestre),
    CONSTRAINT ck_periodo_sem     CHECK (semestre IN (1, 2)),
    CONSTRAINT ck_periodo_datas   CHECK (data_fim > data_inicio)
);

CREATE TABLE turma (
    id_turma       INT        NOT NULL AUTO_INCREMENT,
    id_disciplina  INT        NOT NULL,
    id_periodo     INT        NOT NULL,
    codigo         VARCHAR(5) NOT NULL,
    vagas          SMALLINT   NOT NULL,
    diario_fechado BOOLEAN    NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_turma            PRIMARY KEY (id_turma),
    CONSTRAINT uq_turma_disc_per_cod UNIQUE (id_disciplina, id_periodo, codigo),
    CONSTRAINT fk_turma_disciplina FOREIGN KEY (id_disciplina) REFERENCES disciplina (id_disciplina),
    CONSTRAINT fk_turma_periodo    FOREIGN KEY (id_periodo)    REFERENCES periodo_letivo (id_periodo),
    CONSTRAINT ck_turma_vagas      CHECK (vagas > 0)
);

CREATE TABLE turma_professor (
    id_turma     INT         NOT NULL,
    id_professor INT         NOT NULL,
    papel        VARCHAR(12) NOT NULL,
    CONSTRAINT pk_turma_professor PRIMARY KEY (id_turma, id_professor),
    CONSTRAINT fk_tp_turma        FOREIGN KEY (id_turma)     REFERENCES turma (id_turma),
    CONSTRAINT fk_tp_professor    FOREIGN KEY (id_professor) REFERENCES professor (id_professor),
    CONSTRAINT ck_tp_papel        CHECK (papel IN ('TITULAR', 'COLABORADOR'))
);

-- ---------------------------------------------------------------------
-- Aula (entidade fraca de turma) e avaliacao
-- ---------------------------------------------------------------------
CREATE TABLE aula (
    id_turma    INT          NOT NULL,
    numero_aula SMALLINT     NOT NULL,
    data_aula   DATE         NOT NULL,
    conteudo    VARCHAR(150),
    CONSTRAINT pk_aula       PRIMARY KEY (id_turma, numero_aula),
    CONSTRAINT fk_aula_turma FOREIGN KEY (id_turma) REFERENCES turma (id_turma) ON DELETE CASCADE,
    CONSTRAINT ck_aula_num   CHECK (numero_aula > 0)
);

CREATE TABLE avaliacao (
    id_avaliacao   INT          NOT NULL AUTO_INCREMENT,
    id_turma       INT          NOT NULL,
    descricao      VARCHAR(60)  NOT NULL,
    peso           DECIMAL(4,2) NOT NULL,
    data_avaliacao DATE         NOT NULL,
    CONSTRAINT pk_avaliacao       PRIMARY KEY (id_avaliacao),
    CONSTRAINT uq_avaliacao_turma UNIQUE (id_avaliacao, id_turma),   -- alvo das FKs compostas de nota
    CONSTRAINT fk_avaliacao_turma FOREIGN KEY (id_turma) REFERENCES turma (id_turma),
    CONSTRAINT ck_avaliacao_peso  CHECK (peso > 0)
);

-- ---------------------------------------------------------------------
-- Matricula (entidade associativa aluno x turma), nota e frequencia
-- NAO ha coluna de media nem de situacao final: sao derivadas (RN19).
-- ---------------------------------------------------------------------
CREATE TABLE matricula (
    id_aluno       INT         NOT NULL,
    id_turma       INT         NOT NULL,
    data_matricula DATE        NOT NULL,
    status         VARCHAR(10) NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT pk_matricula        PRIMARY KEY (id_aluno, id_turma),
    CONSTRAINT fk_matricula_aluno  FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno),
    CONSTRAINT fk_matricula_turma  FOREIGN KEY (id_turma) REFERENCES turma (id_turma),
    CONSTRAINT ck_matricula_status CHECK (status IN ('ATIVA', 'TRANCADA'))
);

CREATE TABLE nota (
    id_aluno     INT          NOT NULL,
    id_turma     INT          NOT NULL,
    id_avaliacao INT          NOT NULL,
    valor        DECIMAL(4,2) NOT NULL,
    CONSTRAINT pk_nota           PRIMARY KEY (id_aluno, id_turma, id_avaliacao),
    CONSTRAINT fk_nota_matricula FOREIGN KEY (id_aluno, id_turma)     REFERENCES matricula (id_aluno, id_turma),
    CONSTRAINT fk_nota_avaliacao FOREIGN KEY (id_avaliacao, id_turma) REFERENCES avaliacao (id_avaliacao, id_turma),
    CONSTRAINT ck_nota_valor     CHECK (valor BETWEEN 0 AND 10)
);

CREATE TABLE frequencia (
    id_aluno    INT      NOT NULL,
    id_turma    INT      NOT NULL,
    numero_aula SMALLINT NOT NULL,
    presente    BOOLEAN  NOT NULL,
    CONSTRAINT pk_frequencia           PRIMARY KEY (id_aluno, id_turma, numero_aula),
    CONSTRAINT fk_frequencia_matricula FOREIGN KEY (id_aluno, id_turma)    REFERENCES matricula (id_aluno, id_turma),
    CONSTRAINT fk_frequencia_aula      FOREIGN KEY (id_turma, numero_aula) REFERENCES aula (id_turma, numero_aula)
);

-- ---------------------------------------------------------------------
-- Views que apuram os dados derivados (a media nunca fica "velha")
-- ---------------------------------------------------------------------

-- Media ponderada pelos pesos, so das avaliacoes que ja tem nota (RN16)
CREATE VIEW vw_media_matricula AS
SELECT n.id_aluno,
       n.id_turma,
       ROUND(SUM(n.valor * a.peso) / SUM(a.peso), 2) AS media
FROM nota n
JOIN avaliacao a ON a.id_avaliacao = n.id_avaliacao AND a.id_turma = n.id_turma
GROUP BY n.id_aluno, n.id_turma;

-- Presencas sobre as aulas registradas; aula sem registro conta como falta (RN17)
CREATE VIEW vw_frequencia_matricula AS
SELECT m.id_aluno,
       m.id_turma,
       COUNT(au.numero_aula) AS total_aulas,
       SUM(CASE WHEN f.presente = TRUE THEN 1 ELSE 0 END) AS presencas
FROM matricula m
JOIN aula au ON au.id_turma = m.id_turma
LEFT JOIN frequencia f ON f.id_aluno = m.id_aluno
                      AND f.id_turma = au.id_turma
                      AND f.numero_aula = au.numero_aula
GROUP BY m.id_aluno, m.id_turma;

-- Situacao final conforme RN18 (75% de frequencia e media 6,0)
CREATE VIEW vw_resultado_matricula AS
SELECT m.id_aluno,
       m.id_turma,
       t.id_disciplina,
       t.id_periodo,
       md.media,
       fr.total_aulas,
       fr.presencas,
       CASE WHEN fr.total_aulas > 0
            THEN ROUND(100.0 * fr.presencas / fr.total_aulas, 1) END AS frequencia_pct,
       CASE
           WHEN m.status = 'TRANCADA' THEN 'TRANCADA'
           WHEN t.diario_fechado = FALSE THEN 'EM CURSO'
           WHEN COALESCE(100.0 * fr.presencas / fr.total_aulas, 0) < 75 THEN 'REPROVADO POR FALTA'
           WHEN COALESCE(md.media, 0) < 6 THEN 'REPROVADO POR NOTA'
           ELSE 'APROVADO'
       END AS resultado
FROM matricula m
JOIN turma t ON t.id_turma = m.id_turma
LEFT JOIN vw_media_matricula       md ON md.id_aluno = m.id_aluno AND md.id_turma = m.id_turma
LEFT JOIN vw_frequencia_matricula  fr ON fr.id_aluno = m.id_aluno AND fr.id_turma = m.id_turma;
