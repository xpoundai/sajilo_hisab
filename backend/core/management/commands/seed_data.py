"""
Seed data management command for Sajilo Hisab.
Creates realistic Nepali business demo data.
"""
import random
from decimal import Decimal
from datetime import date, timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.db import transaction

from core.models import Business, PlatformUser, ActivityLog
from accounts.models import BusinessUser
from inventory.models import Item, StockEntry
from transactions.models import Party, Bank, Wallet, Transaction, TransactionItem
from payments.models import Payment, CashBook, CashAdjustment


class Command(BaseCommand):
    help = 'Seed database with demo data for Sajilo Hisab'

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write('🌱 Seeding Sajilo Hisab database...\n')

        # Clear existing data
        self.stdout.write('  Clearing old data...')
        Payment.objects.all().delete()
        TransactionItem.objects.all().delete()
        Transaction.objects.all().delete()
        StockEntry.objects.all().delete()
        Item.objects.all().delete()
        Party.objects.all().delete()
        Wallet.objects.all().delete()
        Bank.objects.all().delete()
        CashAdjustment.objects.all().delete()
        CashBook.objects.all().delete()
        ActivityLog.objects.all().delete()
        BusinessUser.objects.all().delete()
        PlatformUser.objects.all().delete()
        Business.objects.all().delete()
        User.objects.all().delete()

        # ─── 1. Super Admin ─────────────────────────
        self.stdout.write('  Creating Super Admin...')
        admin_auth = User.objects.create_superuser(
            username='superadmin', password='admin123',
            email='admin@sajilohisab.com', first_name='Platform', last_name='Admin'
        )
        PlatformUser.objects.create(user=admin_auth, is_platform_admin=True)

        # ─── 2. Businesses ──────────────────────────
        businesses_data = [
            {
                'name': 'Hari General Store', 'owner': 'Hari Prasad Sharma',
                'phone': '9841234567', 'address': 'Asan, Kathmandu',
                'plan': 'pro', 'status': 'active',
            },
            {
                'name': 'Sita Electronics', 'owner': 'Sita Devi Gurung',
                'phone': '9856789012', 'address': 'Lakeside, Pokhara',
                'plan': 'basic', 'status': 'active',
            },
            {
                'name': 'Ram Textiles', 'owner': 'Ram Bahadur Rai',
                'phone': '9812345678', 'address': 'Main Road, Biratnagar',
                'plan': 'premium', 'status': 'trial',
            },
        ]

        items_catalog = {
            'Hari General Store': [
                ('Basmati Rice', 'kg', 50, 85, 100),
                ('Masoor Dal', 'kg', 30, 140, 170),
                ('Sugar', 'kg', 40, 95, 115),
                ('Mustard Oil', 'litre', 20, 210, 250),
                ('Wheat Flour', 'kg', 35, 55, 70),
                ('Surf Excel', 'pcs', 60, 45, 60),
                ('Wai Wai Noodles', 'pcs', 100, 18, 25),
                ('Glucose Biscuit', 'pcs', 80, 12, 20),
                ('Salt', 'kg', 25, 20, 30),
                ('Tea (Tokla)', 'pcs', 40, 85, 110),
            ],
            'Sita Electronics': [
                ('LED Bulb 9W', 'pcs', 100, 80, 120),
                ('Extension Board', 'pcs', 30, 250, 400),
                ('USB Cable', 'pcs', 50, 60, 120),
                ('Phone Charger', 'pcs', 40, 200, 350),
                ('HDMI Cable', 'pcs', 20, 150, 300),
                ('Earphones', 'pcs', 60, 80, 180),
                ('Power Bank 10000mAh', 'pcs', 15, 800, 1400),
                ('Mouse (Wireless)', 'pcs', 25, 350, 600),
                ('Keyboard', 'pcs', 15, 500, 900),
                ('Screen Guard', 'pcs', 100, 30, 80),
            ],
            'Ram Textiles': [
                ('Cotton Fabric', 'meter', 200, 120, 180),
                ('Silk Fabric', 'meter', 50, 450, 700),
                ('Polyester Fabric', 'meter', 150, 80, 130),
                ('Denim Fabric', 'meter', 100, 200, 320),
                ('Thread Spool', 'pcs', 300, 15, 30),
                ('Buttons (pack)', 'pcs', 200, 20, 40),
                ('Zipper', 'pcs', 150, 25, 50),
                ('Lace (roll)', 'pcs', 80, 60, 120),
                ('Elastic Band', 'meter', 500, 8, 18),
                ('Sewing Needle Pack', 'pcs', 100, 10, 25),
            ],
        }

        parties_data = {
            'Hari General Store': [
                ('Shyam Grocery', 'customer', '9845112233'),
                ('Maya Kitchen', 'customer', '9867889900'),
                ('Krishna Mart', 'customer', '9811223344'),
                ('Nepal Food Suppliers', 'vendor', '9801122334'),
                ('Himalayan Distributors', 'vendor', '9809988776'),
                ('Lucky Wholesale', 'vendor', '9841555666'),
            ],
            'Sita Electronics': [
                ('Tech House', 'customer', '9856111222'),
                ('Digital Zone', 'customer', '9867222333'),
                ('Smart Solutions', 'customer', '9812333444'),
                ('China Electronics Nepal', 'vendor', '9801444555'),
                ('Sasto Electronics', 'vendor', '9809555666'),
            ],
            'Ram Textiles': [
                ('Fashion Hub', 'customer', '9812666777'),
                ('Style Palace', 'customer', '9845777888'),
                ('Srijana Tailors', 'customer', '9867888999'),
                ('Mumbai Textiles Import', 'vendor', '9801999000'),
                ('Fabric World Nepal', 'vendor', '9809000111'),
                ('Silk Route Traders', 'vendor', '9841111222'),
            ],
        }

        banks_data = [
            ('Nepal Bank Limited', '1234567890'),
            ('NIC Asia Bank', '9876543210'),
            ('Nabil Bank', '5555666677'),
        ]

        wallets_data = [
            ('eSewa', '9841234567'),
            ('Khalti', '9841234567'),
        ]

        for biz_data in businesses_data:
            self.stdout.write(f'  Creating business: {biz_data["name"]}...')

            business = Business.objects.create(
                name=biz_data['name'],
                owner_name=biz_data['owner'],
                phone=biz_data['phone'],
                address=biz_data['address'],
                plan=biz_data['plan'],
                status=biz_data['status'],
                subscription_start=date.today() - timedelta(days=30),
                subscription_expiry=date.today() + timedelta(days=335),
            )

            # Create admin user
            admin_user = User.objects.create_user(
                username=biz_data['phone'],
                password='password123',
                first_name=biz_data['owner'].split()[0],
            )
            admin_bu = BusinessUser.objects.create(
                business=business, auth_user=admin_user,
                name=biz_data['owner'], phone=biz_data['phone'],
                role='admin', permissions=['all'],
            )

            # Create staff user
            staff_phone = f'98{random.randint(10000000, 99999999)}'
            staff_auth = User.objects.create_user(
                username=staff_phone,
                password='password123',
                first_name='Staff',
            )
            staff_bu = BusinessUser.objects.create(
                business=business, auth_user=staff_auth,
                name=f'Staff {biz_data["name"].split()[0]}',
                phone=staff_phone, role='staff',
            )

            # Create CashBook
            cashbook = CashBook.objects.create(business=business, balance=Decimal('25000'))

            # Create Items
            items = []
            for item_data in items_catalog.get(biz_data['name'], []):
                item = Item.objects.create(
                    business=business,
                    name=item_data[0], unit=item_data[1],
                    quantity=Decimal(str(item_data[2])),
                    cost_price=Decimal(str(item_data[3])),
                    selling_price=Decimal(str(item_data[4])),
                    low_stock_threshold=10,
                )
                items.append(item)

            # Create Parties
            parties = []
            for p_data in parties_data.get(biz_data['name'], []):
                party = Party.objects.create(
                    business=business,
                    name=p_data[0], type=p_data[1], phone=p_data[2],
                    balance=Decimal(str(random.randint(-5000, 15000))),
                    total_business=Decimal(str(random.randint(10000, 200000))),
                )
                parties.append(party)

            # Create Banks
            biz_banks = []
            for i, (b_name, b_acc) in enumerate(banks_data[:2]):
                bank = Bank.objects.create(
                    business=business, name=b_name,
                    account_number=b_acc,
                    balance=Decimal(str(random.randint(10000, 100000))),
                )
                biz_banks.append(bank)

            # Create Wallets
            biz_wallets = []
            for w_name, w_phone in wallets_data:
                wallet = Wallet.objects.create(
                    business=business, name=w_name,
                    phone=biz_data['phone'],
                    balance=Decimal(str(random.randint(1000, 20000))),
                    linked_bank=biz_banks[0] if biz_banks else None,
                )
                biz_wallets.append(wallet)

            # Create Transactions
            customers = [p for p in parties if p.type == 'customer']
            vendors = [p for p in parties if p.type == 'vendor']

            for i in range(12):
                txn_date = date.today() - timedelta(days=random.randint(0, 30))
                is_sale = i < 7  # 7 sales, 5 purchases

                if is_sale and customers:
                    party = random.choice(customers)
                    txn_type = 'sale'
                elif vendors:
                    party = random.choice(vendors)
                    txn_type = 'purchase'
                else:
                    continue

                # Pick 1-3 random items
                num_items = random.randint(1, 3)
                selected_items = random.sample(items, min(num_items, len(items)))

                total = Decimal('0')
                txn_items = []
                for item in selected_items:
                    qty = Decimal(str(random.randint(1, 10)))
                    rate = item.selling_price if is_sale else item.cost_price
                    line_total = qty * rate
                    total += line_total
                    txn_items.append((item, qty, rate, line_total))

                # Random payment
                methods = ['cash', 'bank', 'wallet']
                method = random.choice(methods)
                paid_ratio = random.choice([Decimal('0'), Decimal('0.5'), Decimal('1')])
                paid = total * paid_ratio

                if paid >= total:
                    txn_status = 'paid'
                elif paid > 0:
                    txn_status = 'partial'
                else:
                    txn_status = 'credit'

                txn = Transaction.objects.create(
                    business=business, type=txn_type, party=party,
                    total=total, paid=paid, payment_method=method,
                    bank=biz_banks[0] if method == 'bank' and biz_banks else None,
                    wallet=biz_wallets[0] if method == 'wallet' and biz_wallets else None,
                    status=txn_status, date=txn_date, created_by=admin_bu,
                )

                for item, qty, rate, line_total in txn_items:
                    TransactionItem.objects.create(
                        transaction=txn, item=item, item_name=item.name,
                        quantity=qty, rate=rate, total=line_total,
                    )

            # Create Payments
            for i in range(6):
                pay_date = date.today() - timedelta(days=random.randint(0, 20))
                if customers and i < 4:
                    party = random.choice(customers)
                    pay_type = 'received'
                elif vendors:
                    party = random.choice(vendors)
                    pay_type = 'paid'
                else:
                    continue

                method = random.choice(['cash', 'bank', 'wallet'])
                amount = Decimal(str(random.randint(500, 15000)))

                Payment.objects.create(
                    business=business, party=party, amount=amount,
                    type=pay_type, method=method,
                    bank=biz_banks[0] if method == 'bank' and biz_banks else None,
                    wallet=biz_wallets[0] if method == 'wallet' and biz_wallets else None,
                    category='normal', date=pay_date, created_by=admin_bu,
                )

            # Activity Logs
            actions = [
                ('User Login', admin_bu.name, 'system'),
                ('Item Created', 'Rice', 'inventory'),
                ('Sale Created', f'{customers[0].name if customers else "Customer"} - NPR 5000', 'transactions'),
                ('Payment Received', f'{customers[0].name if customers else "Customer"} - NPR 2000', 'payments'),
            ]
            for action, target, module in actions:
                ActivityLog.objects.create(
                    business=business, user_name=admin_bu.name,
                    action=action, target=target, module=module,
                )

        self.stdout.write(self.style.SUCCESS('\n✅ Seed data created successfully!'))
        self.stdout.write('\n📋 Login Credentials:')
        self.stdout.write('  Super Admin: superadmin / admin123')
        self.stdout.write('  Hari General Store (Admin): 9841234567 / password123')
        self.stdout.write('  Sita Electronics (Admin): 9856789012 / password123')
        self.stdout.write('  Ram Textiles (Admin): 9812345678 / password123')
