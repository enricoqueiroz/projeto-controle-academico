namespace AcademicoApp;

// Menu principal: dispara o CRUD de cada tabela e as consultas/relatorios.
public class MenuForm : Form
{
    public MenuForm()
    {
        Text = "Controle Acadêmico - Tema 05";
        Width = 1200; Height = 750;
        IsMdiContainer = true;

        var cadastros = new ToolStripMenuItem("Cadastros (CRUD)");
        foreach (var tabela in Db.Tabelas)
            cadastros.DropDownItems.Add(tabela, null, (s, e) => new CrudForm(tabela) { MdiParent = this }.Show());

        var consultas = new ToolStripMenuItem("Consultas e relatórios", null,
            (s, e) => new ConsultasForm { MdiParent = this }.Show());
        var sair = new ToolStripMenuItem("Sair", null, (s, e) => Close());

        var menu = new MenuStrip();
        menu.Items.AddRange(new ToolStripItem[] { cadastros, consultas, sair });
        MainMenuStrip = menu;
        Controls.Add(menu);
    }
}
