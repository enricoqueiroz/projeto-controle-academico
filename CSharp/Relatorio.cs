using System.Data;
using ClosedXML.Excel;

namespace AcademicoApp;

public static class Relatorio
{
    // Exporta qualquer DataTable (tabela ou resultado de consulta) para um arquivo .xlsx.
    public static void ParaExcel(DataTable? dt, string nome)
    {
        if (dt == null || dt.Rows.Count == 0) { MessageBox.Show("Não há dados para exportar."); return; }
        using var dlg = new SaveFileDialog { Filter = "Excel (*.xlsx)|*.xlsx", FileName = nome + ".xlsx" };
        if (dlg.ShowDialog() != DialogResult.OK) return;
        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add(dt, nome.Length > 31 ? nome[..31] : nome);
        ws.Columns().AdjustToContents();
        wb.SaveAs(dlg.FileName);
        MessageBox.Show("Relatório gerado: " + dlg.FileName);
    }
}
