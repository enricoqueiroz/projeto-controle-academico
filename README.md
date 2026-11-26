# Controle Acadêmico com Pré-requisitos

Projeto Final de **Banco de Dados e Linguagem de Programação I** (IFSP, Câmpus Piracicaba) — Tema 05.

Modelagem completa de um sistema de controle acadêmico em **MySQL 8** (matrizes curriculares versionadas, pré-requisitos como autorrelacionamento N:N, turmas com coadministração, matrícula, notas e frequência) e uma aplicação **C# Windows Forms** com CRUD de todas as tabelas e consultas parametrizadas com exportação para Excel.

## Destaques do modelo

- Generalização `pessoa` → `aluno` / `professor` (cobertura parcial, disjunção compartilhada)
- Autorrelacionamento N:N de `disciplina` (pré-requisitos) com `CHECK` contra auto-referência
- Matriz curricular versionada: a mesma disciplina muda de semestre e carga horária entre matrizes
- Média, frequência e situação final **não são armazenadas**: são derivadas por views (`vw_media_matricula`, `vw_frequencia_matricula`, `vw_resultado_matricula`), então uma correção de nota nunca deixa o dado desatualizado
- 17 tabelas, 3 views, restrições `PK`, `FK` (inclusive compostas), `UNIQUE` e `CHECK`
- Carga de dados com ~1.900 linhas e casos de borda (curso sem matriz, professor que também é aluno, matrícula trancada, reprovação por nota e por falta, diário aberto etc.)

## Estrutura

```
.
├── SQL/
│   ├── 01_ddl.sql          # banco, tabelas, restrições e views (recria o banco do zero)
│   ├── 02_carga.sql        # carga inicial de dados
│   ├── 03_consultas.sql    # 10 consultas com pergunta e resultado
│   └── 04_integridade.sql  # 3 comandos que devem falhar (referencial, chave, domínio)
├── CSharp/                 # aplicação Windows Forms (.NET 8)
├── docs/
│   └── Relatorio_Projeto_Final.pdf   # minimundo, MER, modelo lógico e demais entregáveis
└── README.md
```

## Como executar

**Requisitos:** MySQL 8.0.16 ou superior (o `CHECK` só é aplicado a partir dessa versão); Windows com .NET 8 SDK ou Visual Studio 2022.

1. No MySQL, execute na ordem os scripts da pasta `SQL/`: `01_ddl.sql` e `02_carga.sql`. O `03_consultas.sql` e o `04_integridade.sql` são opcionais.
2. Em `CSharp/Db.cs`, troque `SUA_SENHA` pela senha do seu MySQL (e o servidor, se não for `localhost`). **Caso não tenha uma senha deixa como `Pwd=`.**
3. Dentro de `CSharp/`, rode `dotnet run` ou abra `AcademicoApp.csproj` no Visual Studio.

## Aplicação

- **Cadastros (CRUD):** um único formulário genérico atende todas as tabelas (`MySqlDataAdapter` + `MySqlCommandBuilder`). Quando o banco recusa uma operação (PK, FK, UNIQUE, CHECK), a mensagem do SGBD é exibida: a integridade é garantida pelo banco, não pela aplicação.
- **Consultas e relatórios:** as 10 consultas do `03_consultas.sql`, com parâmetros editáveis (`@ano`, `@semestre`, `@codigo`...) e exportação para `.xlsx`.

## Consultas

| # | Pergunta |
|---|----------|
| Q1 | Quais alunos podem se matricular numa disciplina (divisão relacional com `NOT EXISTS` duplo)? |
| Q2 | Taxa de reprovação por disciplina no semestre |
| Q3 | Disciplinas da matriz sem turma no semestre |
| Q4 | Carga horária já cursada por aluno |
| Q5 | Professores com mais de quatro turmas |
| Q6 | Alunos em risco nas turmas em curso |
| Q7 | Pré-requisitos diretos de cada disciplina |
| Q8 | O que mudou entre as matrizes de ADS 2019 e 2025 |
| Q9 | Turmas com coadministração |
| Q10 | Pessoas por papel (aluno, professor, ambos, nenhum) |

## Tecnologias

MySQL 8 · C# / .NET 8 (Windows Forms) · MySql.Data 8.4.0 · ClosedXML 0.102.2 · brModelo (modelo conceitual). Claude (Anthropic) foi usado como apoio na modelagem, nos scripts, na carga de dados e na documentação.

## Integrantes

- Bruno Marcuz Spezzotto
- Enrico Galdino Queiroz
- Lucas Antunes de Souza
- Thiago Rochelle Bortoletto

Profs.: Luis Fernando Lopes Grim e Moacir Degaspari Junior — IFSP Piracicaba, 2026.
