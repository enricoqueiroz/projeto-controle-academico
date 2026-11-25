using System.Data;

namespace AcademicoApp;

public class ConsultasForm : Form
{
    readonly ComboBox lista = new() { Dock = DockStyle.Top, DropDownStyle = ComboBoxStyle.DropDownList };
    readonly Label pergunta = new() { Dock = DockStyle.Top, Height = 48, Padding = new Padding(4) };
    readonly FlowLayoutPanel painel = new() { Dock = DockStyle.Top, Height = 40 };
    readonly DataGridView grid = new()
    {
        Dock = DockStyle.Fill, ReadOnly = true, AllowUserToAddRows = false,
        AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells
    };
    readonly Dictionary<string, TextBox> campos = new();
    DataTable? resultado;

    public ConsultasForm()
    {
        Text = "Consultas e relatórios";
        Width = 1100; Height = 650;
        lista.Items.AddRange(Catalogo.Todas.Select(c => (object)c.Titulo).ToArray());

        var barra = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 40 };
        var executar = new Button { Text = "Executar", AutoSize = true };
        var exportar = new Button { Text = "Exportar para Excel", AutoSize = true };
        executar.Click += (s, e) => Executar();
        exportar.Click += (s, e) => Relatorio.ParaExcel(resultado, Atual().Titulo.Split(' ')[0]);
        barra.Controls.AddRange(new Control[] { executar, exportar });

        Controls.Add(grid);
        Controls.Add(barra);
        Controls.Add(painel);
        Controls.Add(pergunta);
        Controls.Add(lista);
        lista.SelectedIndexChanged += (s, e) => Mostrar();
        lista.SelectedIndex = 0;
    }

    Consulta Atual() => Catalogo.Todas[lista.SelectedIndex];

    void Mostrar()
    {
        var c = Atual();
        pergunta.Text = c.Pergunta;
        resultado = null;            // evita exportar o resultado da consulta anterior com o nome da nova
        grid.DataSource = null;
        painel.Controls.Clear();
        campos.Clear();
        foreach (var (nome, padrao) in c.Parametros)
        {
            painel.Controls.Add(new Label { Text = nome + ":", AutoSize = true, Padding = new Padding(8, 6, 0, 0) });
            var caixa = new TextBox { Text = padrao, Width = 70 };
            campos[nome] = caixa;
            painel.Controls.Add(caixa);
        }
    }

    void Executar()
    {
        try
        {
            resultado = Db.Consultar(Atual().Sql, campos.Select(kv => (kv.Key, kv.Value.Text)));
            grid.DataSource = resultado;
        }
        catch (Exception ex) { MessageBox.Show(ex.Message, "Erro na consulta"); }
    }
}
