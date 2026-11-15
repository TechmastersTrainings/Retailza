import io
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

SAMPLE_PRODUCTS = [
    {
        "name": "Aashirvaad Shudh Chakki Atta 5kg",
        "selling_price": 245.00,
        "purchase_price": 215.00,
        "stock_quantity": 20,
        "unit": "packet",
        "category": "Atta & Flours",
        "barcode": "8901030383123",
        "min_stock": 5
    },
    {
        "name": "Fortune Sunlite Refined Sunflower Oil 1L",
        "selling_price": 135.00,
        "purchase_price": 118.00,
        "stock_quantity": 30,
        "unit": "packet",
        "category": "Edible Oils",
        "barcode": "8906007281012",
        "min_stock": 5
    },
    {
        "name": "Tata Salt Vacuum Evaporated 1kg",
        "selling_price": 28.00,
        "purchase_price": 23.50,
        "stock_quantity": 50,
        "unit": "packet",
        "category": "Salt & Spices",
        "barcode": "8901030012009",
        "min_stock": 10
    },
    {
        "name": "Maggi 2-Minute Masala Noodles 70g",
        "selling_price": 14.00,
        "purchase_price": 11.50,
        "stock_quantity": 96,
        "unit": "piece",
        "category": "Instant Food",
        "barcode": "8901058852335",
        "min_stock": 12
    },
    {
        "name": "Basmati Rice Premium 1kg",
        "selling_price": 95.00,
        "purchase_price": 78.00,
        "stock_quantity": 40,
        "unit": "kg",
        "category": "Rice & Grains",
        "barcode": "8902040100451",
        "min_stock": 5
    }
]


def generate_excel_template() -> io.BytesIO:
    """Generate a formatted Excel (.xlsx) template with sample products and styling."""
    wb = Workbook()
    ws = wb.active
    if ws is None:
        ws = wb.create_sheet(title="Products_Catalog")
    else:
        ws.title = "Products_Catalog"

    # Ensure grid lines are visible
    ws.views.sheetView[0].showGridLines = True

    # Styling definitions
    header_fill = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")  # Deep Navy Blue
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    sample_font = Font(name="Calibri", size=10, color="1F2937")
    thin_border = Border(
        left=Side(style='thin', color='D1D5DB'),
        right=Side(style='thin', color='D1D5DB'),
        top=Side(style='thin', color='D1D5DB'),
        bottom=Side(style='thin', color='D1D5DB')
    )

    headers = [
        "Product Name *",
        "Selling Price (₹) *",
        "Purchase Price (₹)",
        "Stock Quantity",
        "Unit",
        "Category",
        "Barcode",
        "Min Stock Alert"
    ]

    # Write Headers
    ws.append(headers)
    for col_idx in range(1, len(headers) + 1):
        cell = ws.cell(row=1, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws.row_dimensions[1].height = 28

    # Write Sample Rows
    for row_idx, item in enumerate(SAMPLE_PRODUCTS, start=2):
        row_values = [
            item["name"],
            item["selling_price"],
            item["purchase_price"],
            item["stock_quantity"],
            item["unit"],
            item["category"],
            item["barcode"],
            item["min_stock"]
        ]
        ws.append(row_values)

        for col_idx in range(1, len(headers) + 1):
            cell = ws.cell(row=row_idx, column=col_idx)
            cell.font = sample_font
            cell.border = thin_border
            if col_idx in [2, 3]:  # Prices
                cell.number_format = '₹#,##0.00'
                cell.alignment = Alignment(horizontal="right", vertical="center")
            elif col_idx in [4, 8]:  # Quantities
                cell.number_format = '#,##0.00'
                cell.alignment = Alignment(horizontal="right", vertical="center")
            elif col_idx in [5, 7]:  # Unit, Barcode
                cell.alignment = Alignment(horizontal="center", vertical="center")
            else:
                cell.alignment = Alignment(horizontal="left", vertical="center")
        ws.row_dimensions[row_idx].height = 20

    # Auto-adjust column widths
    column_widths = [40, 18, 18, 15, 12, 20, 18, 16]
    for idx, width in enumerate(column_widths, start=1):
        col_letter = chr(64 + idx)
        ws.column_dimensions[col_letter].width = width

    # Save to BytesIO
    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return buf


def generate_word_template() -> io.BytesIO:
    """Generate a formatted Word (.docx) template with instructions and table."""
    doc = Document()

    # Document Title
    title = doc.add_heading("Retailza - Bulk Product Upload Template", level=1)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in title.runs:
        run.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)
        run.font.name = "Calibri"

    subtitle = doc.add_paragraph("थोक सामान सूची फ़ाइल (Retailza Catalog Import)")
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in subtitle.runs:
        run.font.size = Pt(11)
        run.font.italic = True
        run.font.color.rgb = RGBColor(0x4B, 0x55, 0x63)

    # Instructions box
    p_inst = doc.add_paragraph()
    run_inst_title = p_inst.add_run("Instructions / निर्देश:\n")
    run_inst_title.bold = True
    run_inst_title.font.color.rgb = RGBColor(0x11, 0x18, 0x27)

    instructions = [
        "1. Fill your products in the table below. You can add more rows as needed.",
        "2. 'Product Name' and 'Selling Price' are mandatory fields (*).",
        "3. Units can be: piece, packet, kg, g, l, ml, box, meter.",
        "4. Save and upload this document (.docx) directly into Retailza mobile app or portal."
    ]
    for inst in instructions:
        p = doc.add_paragraph(inst, style='List Bullet')
        p.paragraph_format.space_after = Pt(2)

    doc.add_paragraph()  # spacer

    headers = [
        "Product Name *",
        "Selling Price (₹) *",
        "Purchase Price (₹)",
        "Stock Qty",
        "Unit",
        "Category",
        "Barcode",
        "Min Stock"
    ]

    # Create Table
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    # Header Row
    hdr_cells = table.rows[0].cells
    for i, header_text in enumerate(headers):
        hdr_cells[i].text = header_text
        shading = parse_xml(r'<w:shd {} w:fill="1E3A8A"/>'.format(nsdecls('w')))
        hdr_cells[i]._tc.get_or_add_tcPr().append(shading)
        for p in hdr_cells[i].paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.bold = True
                r.font.size = Pt(9.5)
                r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
                r.font.name = "Calibri"

    # Add sample rows
    for item in SAMPLE_PRODUCTS:
        row_cells = table.add_row().cells
        row_values = [
            item["name"],
            f"{item['selling_price']:.2f}",
            f"{item['purchase_price']:.2f}",
            str(item["stock_quantity"]),
            item["unit"],
            item["category"],
            item["barcode"],
            str(item["min_stock"])
        ]
        for i, val in enumerate(row_values):
            row_cells[i].text = str(val)
            shading = parse_xml(r'<w:shd {} w:fill="F9FAFB"/>'.format(nsdecls('w')))
            row_cells[i]._tc.get_or_add_tcPr().append(shading)
            for p in row_cells[i].paragraphs:
                p.paragraph_format.space_before = Pt(3)
                p.paragraph_format.space_after = Pt(3)
                if i in [1, 2, 3, 7]:
                    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
                elif i in [4, 6]:
                    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                else:
                    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                for r in p.runs:
                    r.font.size = Pt(9)
                    r.font.color.rgb = RGBColor(0x1F, 0x29, 0x37)
                    r.font.name = "Calibri"

    buf = io.BytesIO()
    doc.save(buf)
    buf.seek(0)
    return buf
