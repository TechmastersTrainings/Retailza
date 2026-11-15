import csv
import io
import re
from decimal import Decimal, InvalidOperation
from typing import List, Dict, Any, Tuple, Optional
from openpyxl import load_workbook
from docx import Document

# Column alias dictionary for flexible header mapping
COLUMN_ALIASES = {
    "name": [
        "product name", "product", "item name", "item", "name", "title",
        "product_name", "item_name", "सामान का नाम", "सामान", "उत्पाद"
    ],
    "selling_price": [
        "selling price", "selling_price", "sale price", "sale_price", "selling price (₹)",
        "selling price (rs)", "price", "rate", "mrp", "विक्रय मूल्य", "कीमत", "बिक्री मूल्य"
    ],
    "purchase_price": [
        "purchase price", "purchase_price", "cost price", "cost_price", "purchase price (₹)",
        "purchase price (rs)", "cost", "buy price", "खरीद मूल्य", "लागत मूल्य"
    ],
    "stock_quantity": [
        "stock quantity", "stock_quantity", "stock qty", "quantity", "qty", "stock",
        "opening stock", "initial stock", "मात्रा", "स्टॉक"
    ],
    "unit": [
        "unit", "uom", "unit of measure", "unit type", "पैकेट/किलो", "इकाई"
    ],
    "category": [
        "category", "item category", "group", "product group", "श्रेणी", "वर्ग"
    ],
    "barcode": [
        "barcode", "bar code", "upc", "ean", "sku", "code", "बारकोड"
    ],
    "min_stock_threshold": [
        "min stock alert", "min stock", "min_stock", "threshold", "min threshold",
        "minimum stock", "low stock alert", "अलर्ट सीमा"
    ]
}


def _clean_header(val: Any) -> str:
    if val is None:
        return ""
    text = str(val).strip().lower()
    # Remove asterisks, parentheses, brackets, symbols
    text = re.sub(r'[*()\[\]₹]', '', text).strip()
    # Replace multiple spaces/underscores with single space
    text = re.sub(r'[\s_]+', ' ', text)
    return text


def _map_header_to_field(header_str: str) -> Optional[str]:
    cleaned = _clean_header(header_str)
    if not cleaned:
        return None
    # 1. Exact match pass
    for field, aliases in COLUMN_ALIASES.items():
        if cleaned in aliases:
            return field
    # 2. Substring match pass with longest aliases first to avoid collision (e.g. price vs purchase price)
    all_pairs = []
    for field, aliases in COLUMN_ALIASES.items():
        for alias in aliases:
            all_pairs.append((len(alias), alias, field))
    all_pairs.sort(key=lambda x: x[0], reverse=True)
    for _, alias, field in all_pairs:
        if alias in cleaned:
            return field
    return None


def _clean_numeric(val: Any, default: Decimal = Decimal("0.00")) -> Tuple[Decimal, bool]:
    """Clean and parse a numeric value, stripping currency symbols and formatting commas."""
    if val is None:
        return default, True
    val_str = str(val).strip()
    if not val_str:
        return default, True

    # Remove currency symbols and commas
    cleaned = re.sub(r'[₹$€£, ]', '', val_str)
    # Remove "Rs." or "rs" prefix if present
    cleaned = re.sub(r'(?i)rs\.?', '', cleaned).strip()

    try:
        dec = Decimal(cleaned)
        return dec, True
    except (InvalidOperation, ValueError):
        return default, False


def _clean_unit(val: Any) -> str:
    if not val:
        return "piece"
    u = str(val).strip().lower()
    if u in ["kg", "kgs", "kilogram", "kilo"]:
        return "kg"
    if u in ["g", "gm", "gms", "gram"]:
        return "g"
    if u in ["l", "ltr", "litre", "liter"]:
        return "l"
    if u in ["ml", "millilitre", "milliliter"]:
        return "ml"
    if u in ["pkt", "packet", "packets", "pack"]:
        return "packet"
    if u in ["pc", "pcs", "piece", "pieces"]:
        return "piece"
    if u in ["box", "boxes", "carton"]:
        return "box"
    if u in ["mtr", "meter", "m"]:
        return "meter"
    return u or "piece"


def parse_excel_file(content: bytes) -> List[Dict[str, Any]]:
    """Parse Excel (.xlsx) file bytes into raw product row dictionaries."""
    wb = load_workbook(io.BytesIO(content), data_only=True)
    ws = wb.active
    if not ws:
        return []

    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return []

    # Find the header row (first non-empty row)
    header_row_idx = 0
    headers_raw = None
    for idx, r in enumerate(rows):
        if any(cell is not None and str(cell).strip() != "" for cell in r):
            header_row_idx = idx
            headers_raw = r
            break

    if headers_raw is None:
        return []

    # Map headers to canonical field names
    col_map: Dict[int, str] = {}
    for col_idx, h in enumerate(headers_raw):
        field = _map_header_to_field(h)
        if field:
            col_map[col_idx] = field

    raw_items = []
    for row_idx in range(header_row_idx + 1, len(rows)):
        r = rows[row_idx]
        if not any(cell is not None and str(cell).strip() != "" for cell in r):
            continue  # skip completely blank rows

        item_dict = {"_row_number": row_idx + 1}
        for col_idx, field in col_map.items():
            if col_idx < len(r):
                item_dict[field] = r[col_idx]
        raw_items.append(item_dict)

    return raw_items


def parse_csv_file(content: bytes) -> List[Dict[str, Any]]:
    """Parse CSV file bytes into raw product row dictionaries."""
    try:
        decoded = content.decode("utf-8-sig")
    except UnicodeDecodeError:
        decoded = content.decode("latin-1")

    reader = csv.reader(io.StringIO(decoded))
    rows = list(reader)
    if not rows:
        return []

    header_row_idx = 0
    headers_raw = None
    for idx, r in enumerate(rows):
        if any(cell.strip() != "" for cell in r):
            header_row_idx = idx
            headers_raw = r
            break

    if headers_raw is None:
        return []

    col_map: Dict[int, str] = {}
    for col_idx, h in enumerate(headers_raw):
        field = _map_header_to_field(h)
        if field:
            col_map[col_idx] = field

    raw_items = []
    for row_idx in range(header_row_idx + 1, len(rows)):
        r = rows[row_idx]
        if not any(cell.strip() != "" for cell in r):
            continue

        item_dict = {"_row_number": row_idx + 1}
        for col_idx, field in col_map.items():
            if col_idx < len(r):
                item_dict[field] = r[col_idx]
        raw_items.append(item_dict)

    return raw_items


def parse_word_file(content: bytes) -> List[Dict[str, Any]]:
    """
    Parse Word (.docx) file bytes into raw product row dictionaries.
    Supports tables and fallback bullet/delimited lists.
    """
    doc = Document(io.BytesIO(content))
    raw_items = []
    current_row_num = 1

    # 1. Parse tables if present
    for table_idx, table in enumerate(doc.tables):
        if len(table.rows) < 2:
            continue

        hdr_row = [cell.text.strip() for cell in table.rows[0].cells]
        col_map: Dict[int, str] = {}
        for col_idx, h in enumerate(hdr_row):
            field = _map_header_to_field(h)
            if field:
                col_map[col_idx] = field

        # If headers couldn't be matched by name, check if table has standard 8 or 6 columns
        if "name" not in col_map.values() and len(hdr_row) >= 2:
            default_cols = ["name", "selling_price", "purchase_price", "stock_quantity", "unit", "category", "barcode", "min_stock_threshold"]
            for i in range(min(len(hdr_row), len(default_cols))):
                col_map[i] = default_cols[i]

        for row_idx in range(1, len(table.rows)):
            row = table.rows[row_idx]
            cell_texts = [c.text.strip() for c in row.cells]
            if not any(cell_texts):
                continue

            item_dict = {"_row_number": current_row_num}
            current_row_num += 1

            for col_idx, field in col_map.items():
                if col_idx < len(cell_texts):
                    item_dict[field] = cell_texts[col_idx]

            raw_items.append(item_dict)

    # 2. If no tables or no items found in tables, check paragraphs
    if not raw_items:
        for p in doc.paragraphs:
            text = p.text.strip()
            if not text or len(text) < 3:
                continue

            # Check if this paragraph is a key-value or delimited line:
            # e.g.: "Product: Tata Salt, Price: 28, Purchase: 22, Qty: 50"
            # OR "Tata Salt | 28 | 22 | 50 | packet | Groceries"
            if any(sep in text for sep in [":", "|", ","]):
                item_dict = _parse_line_to_item(text, current_row_num)
                if item_dict and item_dict.get("name"):
                    raw_items.append(item_dict)
                    current_row_num += 1

    return raw_items


def _parse_line_to_item(line: str, row_num: int) -> Optional[Dict[str, Any]]:
    """Helper to parse a single line of text with key:value pairs or delimiters."""
    item: Dict[str, Any] = {"_row_number": row_num}

    # Case 1: Key-Value pairs with colon, e.g. "Name: Rice, Price: 80, Stock: 20"
    if ":" in line:
        parts = re.split(r'[,|;]', line)
        for part in parts:
            if ":" in part:
                k, v = part.split(":", 1)
                field = _map_header_to_field(k.strip())
                if field:
                    item[field] = v.strip()
        if item.get("name"):
            return item

    # Case 2: Delimited with pipe or comma
    delim = "|" if "|" in line else ("," if "," in line else None)
    if delim:
        tokens = [t.strip() for t in line.split(delim)]
        if len(tokens) >= 2:
            item["name"] = tokens[0]
            item["selling_price"] = tokens[1]
            if len(tokens) > 2:
                item["purchase_price"] = tokens[2]
            if len(tokens) > 3:
                item["stock_quantity"] = tokens[3]
            if len(tokens) > 4:
                item["unit"] = tokens[4]
            if len(tokens) > 5:
                item["category"] = tokens[5]
            if len(tokens) > 6:
                item["barcode"] = tokens[6]
            return item

    return None


def validate_and_normalize_items(
    raw_items: List[Dict[str, Any]],
    existing_barcodes: set
) -> List[Dict[str, Any]]:
    """
    Validates, cleans, and standardizes raw item dictionaries.
    Checks required fields, valid positive prices, unit normalization,
    and duplicate barcodes within the batch or existing inventory.
    """
    seen_batch_barcodes = set()
    validated_items = []

    for item in raw_items:
        row_num = item.get("_row_number", 0)
        errors = []

        # 1. Product Name (Mandatory)
        raw_name = item.get("name")
        name = str(raw_name).strip() if raw_name is not None else ""
        if not name:
            errors.append("Product name is required.")

        # 2. Selling Price (Mandatory, positive)
        selling_price, sp_valid = _clean_numeric(item.get("selling_price"))
        if not sp_valid:
            errors.append("Invalid selling price format.")
        elif selling_price < Decimal("0.00"):
            errors.append("Selling price cannot be negative.")
        elif selling_price == Decimal("0.00") and name:
            errors.append("Selling price must be greater than 0.")

        # 3. Purchase Price (Optional, defaults to 0.00)
        purchase_price, pp_valid = _clean_numeric(item.get("purchase_price"), Decimal("0.00"))
        if not pp_valid:
            errors.append("Invalid purchase price format.")
        elif purchase_price < Decimal("0.00"):
            errors.append("Purchase price cannot be negative.")

        # 4. Stock Quantity (Optional, defaults to 0.000)
        stock_qty, sq_valid = _clean_numeric(item.get("stock_quantity"), Decimal("0.000"))
        if not sq_valid:
            errors.append("Invalid stock quantity format.")
        elif stock_qty < Decimal("0.000"):
            errors.append("Stock quantity cannot be negative.")

        # 5. Min Stock Threshold (Optional, defaults to 5.000)
        min_stock, ms_valid = _clean_numeric(item.get("min_stock_threshold"), Decimal("5.000"))
        if not ms_valid:
            min_stock = Decimal("5.000")

        # 6. Unit
        unit = _clean_unit(item.get("unit"))

        # 7. Category
        raw_cat = item.get("category")
        category = str(raw_cat).strip() if raw_cat else "General"
        if not category:
            category = "General"

        # 8. Barcode
        raw_bc = item.get("barcode")
        barcode = str(raw_bc).strip() if raw_bc is not None else None
        if barcode:
            # Remove any float decimal in case excel exported barcode as 8901030012009.0
            if barcode.endswith(".0"):
                barcode = barcode[:-2]
            if not barcode:
                barcode = None

        if barcode:
            if barcode in existing_barcodes:
                errors.append(f"Barcode '{barcode}' is already used by an existing product.")
            elif barcode in seen_batch_barcodes:
                errors.append(f"Duplicate barcode '{barcode}' found within this uploaded file.")
            else:
                seen_batch_barcodes.add(barcode)

        is_valid = len(errors) == 0
        error_msg = "; ".join(errors) if errors else None

        validated_items.append({
            "name": name,
            "barcode": barcode,
            "category": category,
            "unit": unit,
            "purchase_price": purchase_price,
            "selling_price": selling_price,
            "stock_quantity": stock_qty,
            "min_stock_threshold": min_stock,
            "is_valid": is_valid,
            "error_message": error_msg,
            "row_number": row_num
        })

    return validated_items
