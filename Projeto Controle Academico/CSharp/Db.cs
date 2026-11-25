using System.Data;
using MySql.Data.MySqlClient;

namespace AcademicoApp;

public static class Db
{
    // >>> Ajuste a senha (e o servidor, se preciso) antes de executar. <<<
    public const string ConnectionString =
        "Server=localhost;Port=3306;Database=controle_academico;Uid=root;Pwd=SUA_SENHA;CharSet=utf8mb4;";

    // Todas as tabelas do modelo (cada uma ganha um CRUD no menu).
    public static readonly string[] Tabelas =
    {
        "pessoa", "pessoa_telefone", "curso", "matriz_curricular", "disciplina", "pre_requisito",
        "matriz_disciplina", "aluno", "professor", "periodo_letivo", "turma", "turma_professor",
        "aula", "avaliacao", "matricula", "nota", "frequencia"
    };

    public static DataTable Consultar(string sql, IEnumerable<(string Nome, string Valor)> parametros)
    {
        using var conn = new MySqlConnection(ConnectionString);
        using var cmd = new MySqlCommand(sql, conn);
        foreach (var (nome, valor) in parametros)
            cmd.Parameters.AddWithValue("@" + nome, int.TryParse(valor, out var i) ? (object)i : valor);
        var dt = new DataTable();
        new MySqlDataAdapter(cmd).Fill(dt);
        return dt;
    }
}
