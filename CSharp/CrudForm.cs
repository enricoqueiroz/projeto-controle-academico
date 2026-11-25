using System.Data;
using MySql.Data.MySqlClient;

namespace AcademicoApp;

// Um unico formulario serve o CRUD de TODAS as tabelas: o MySqlCommandBuilder
// gera INSERT/UPDATE/DELETE a partir do SELECT * e das chaves primarias.
public class CrudForm : Form
{
    readonly string tabela;
    readonly DataGridView grid = new() { Dock = DockStyle.Fill };
    MySqlDataAdapter? adapter;
    MySqlCommandBuilder? builder;
    DataTable dt = new();

    public CrudForm(string tabela)
    {
        this.tabela = tabela;
        Text = "Cadastro: " + tabela;
        Width = 1000; Height = 600;
        var barra = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 40 };
        barra.Controls.Add(Botao("Recarregar", (s, e) => Carregar()));
        barra.Controls.Add(Botao("Salvar alterações", (s, e) => Salvar()));
        barra.Controls.Add(Botao("Excluir linha selecionada", (s, e) => Excluir()));
        barra.Controls.Add(Botao("Exportar para Excel", (s, e) => Relatorio.ParaExcel(dt, tabela)));
        Controls.Add(grid);
        Controls.Add(barra);
        grid.DataError += (s, e) => { MessageBox.Show("Valor inválido: " + e.Exception?.Message); e.ThrowException = false; };
        Load += (s, e) => Carregar();
    }

    static Button Botao(string texto, EventHandler acao)
    {
        var b = new Button { Text = texto, AutoSize = true };
        b.Click += acao;
        return b;
    }

    void Carregar()
    {
        try
        {
            adapter = new MySqlDataAdapter($"SELECT * FROM `{tabela}`", new MySqlConnection(Db.ConnectionString));
            builder = new MySqlCommandBuilder(adapter);
            dt = new DataTable();
            adapter.Fill(dt);
            grid.DataSource = dt;
        }
        catch (Exception ex) { MessageBox.Show(ex.Message, "Erro ao carregar"); }
    }

    void Salvar()
    {
        try
        {
            grid.EndEdit();
            adapter!.Update(dt);
            Carregar();
            MessageBox.Show("Alterações salvas.");
        }
        catch (Exception ex)
        {
            // Mensagem do SGBD (violacao de PK, FK, UNIQUE ou CHECK); descarta a alteracao.
            MessageBox.Show(ex.Message, "O banco recusou a operação");
            Carregar();
        }
    }

    void Excluir()
    {
        if (grid.CurrentRow is { IsNewRow: false } linha)
        {
            grid.Rows.Remove(linha);
            Salvar();
        }
    }
}
