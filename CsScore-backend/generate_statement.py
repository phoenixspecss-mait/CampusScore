from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import random
import datetime

def generate_statement(filename="Demo_Bank_Statement.pdf"):
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter
    
    # Header
    c.setFont("Helvetica-Bold", 18)
    c.drawString(50, height - 50, "Campus Bank - Account Statement")
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 70, "Account Holder: Student User")
    c.drawString(50, height - 85, f"Statement Date: {datetime.date.today().strftime('%Y-%m-%d')}")
    
    # Table Header
    c.setFont("Helvetica-Bold", 12)
    y = height - 130
    c.drawString(50, y, "Date")
    c.drawString(150, y, "Description")
    c.drawString(400, y, "Type")
    c.drawString(480, y, "Amount (INR)")
    
    c.line(50, y - 5, 550, y - 5)
    
    # Generate some realistic transactions
    transactions = [
        {"desc": "UPI/CR/12345/Freelance", "type": "CR", "amt": 250000.00},
        {"desc": "UPI/DR/Zomato", "type": "DR", "amt": 450.00},
        {"desc": "UPI/CR/12346/Tutoring", "type": "CR", "amt": 150000.00},
        {"desc": "UPI/DR/Netflix", "type": "DR", "amt": 199.00},
        {"desc": "UPI/CR/12347/PartTime", "type": "CR", "amt": 120000.00},
        {"desc": "UPI/DR/Rent", "type": "DR", "amt": 8000.00},
        {"desc": "UPI/DR/Spotify", "type": "DR", "amt": 119.00},
        {"desc": "UPI/CR/12348/Scholarship", "type": "CR", "amt": 50000.00},
        {"desc": "UPI/CR/12349/Stipend", "type": "CR", "amt": 35000.00},
        {"desc": "UPI/DR/Groceries", "type": "DR", "amt": 2000.00},
    ]
    
    c.setFont("Helvetica", 11)
    y -= 25
    base_date = datetime.date.today() - datetime.timedelta(days=30)
    
    for tx in transactions:
        tx_date = base_date + datetime.timedelta(days=random.randint(1, 28))
        c.drawString(50, y, tx_date.strftime("%Y-%m-%d"))
        c.drawString(150, y, tx["desc"])
        c.drawString(400, y, tx["type"])
        c.drawString(480, y, f"{tx['amt']:.2f}")
        y -= 20
        
    c.save()
    print(f"Generated clean dummy statement: {filename}")

if __name__ == "__main__":
    generate_statement()
