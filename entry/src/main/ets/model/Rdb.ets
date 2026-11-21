import { relationalStore } from '@kit.ArkData';
import { emitter } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AssetAccount, AccountType, Bill, BillType, Book, Category, RefundStatus } from './Models';
import { CategoryData } from './CategoryData';

export const EVT_DATA_CHANGED: number = 10001;

export class Store {
  private static inst: Store | null = null;

  static get(): Store {
    if (Store.inst === null) {
      Store.inst = new Store();
    }
    return Store.inst;
  }

  private rdb: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  books: Book[] = [];
  categories: Category[] = [];
  accounts: AssetAccount[] = [];
  bills: Bill[] = [];

  ensureInited(ctx: common.Context): Promise<void> {
    if (this.initPromise === null) {
      this.initPromise = this.doInit(ctx);
    }
    return this.initPromise;
  }

  private async doInit(ctx: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'qimiao_book.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.rdb = await relationalStore.getRdbStore(ctx, config);
    await this.createTables();
    await this.seedIfEmpty();
    await this.loadAll();
    this.emitChange();
  }

  private async createTables(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    await db.executeSql('CREATE TABLE IF NOT EXISTS book (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, budget INTEGER NOT NULL DEFAULT 0)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS category (' +
      'id TEXT PRIMARY KEY, name TEXT, icon TEXT, color TEXT, bg TEXT, type TEXT, parentId TEXT)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS account (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, icon TEXT, type TEXT, balance INTEGER, hidden INTEGER)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS bill (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, bookId INTEGER, type TEXT, amount INTEGER, ' +
      'categoryId TEXT, subId TEXT, remark TEXT, occurTime INTEGER, account TEXT, ' +
      'tags TEXT, excludeStat INTEGER, refundStatus TEXT)');
  }

  private async seedIfEmpty(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const rsBook: relationalStore.ResultSet = await db.querySql('SELECT COUNT(*) AS c FROM book', []);
    let bookCount: number = 0;
    if (rsBook.goToNextRow()) {
      bookCount = rsBook.getLong(0);
    }
    rsBook.close();

    const expTree: Category[] = CategoryData.buildExpenseTree();
    const incTree: Category[] = CategoryData.buildIncomeTree();
    const rsCat: relationalStore.ResultSet = await db.querySql('SELECT COUNT(*) AS c FROM category', []);
    let catCount: number = 0;
    if (rsCat.goToNextRow()) {
      catCount = rsCat.getLong(0);
    }
    rsCat.close();
    if (catCount === 0) {
      await this.insertTree(db, expTree, 'expense', '');
      await this.insertTree(db, incTree, 'income', '');
    }

    if (bookCount === 0) {
      const v: relationalStore.ValuesBucket = {
        'name': '我的账本',
        'budget': 500000
      };
      await db.insert('book', v);
      const accounts: AssetAccount[] = [
        new AssetAccount(0, '现金', 'wallet', 'cash', 520050),
        new AssetAccount(0, '微信钱包', 'message', 'wechat', 135820),
        new AssetAccount(0, '招商银行卡', 'building', 'bank', 886600),
        new AssetAccount(0, '信用卡', 'creditcard', 'bank', -120000)
      ];
      for (let i: number = 0; i < accounts.length; i++) {
        const a: AssetAccount = accounts[i];
        const av: relationalStore.ValuesBucket = {
          'name': a.name,
          'icon': a.icon,
          'type': a.type,
          'balance': a.balance,
          'hidden': 0
        };
        await db.insert('account', av);
      }
    }

    const rsBill: relationalStore.ResultSet = await db.querySql('SELECT COUNT(*) AS c FROM bill', []);
    let billCount: number = 0;
    if (rsBill.goToNextRow()) {
      billCount = rsBill.getLong(0);
    }
    rsBill.close();
    if (billCount === 0) {
      await this.seedBills(db);
    }
  }

  private async insertTree(db: relationalStore.RdbStore, tree: Category[], type: string, parentId: string): Promise<void> {
    for (let i: number = 0; i < tree.length; i++) {
      const c: Category = tree[i];
      const cv: relationalStore.ValuesBucket = {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'color': c.color,
        'bg': c.bg,
        'type': type,
        'parentId': parentId
      };
      await db.insert('category', cv);
      if (c.children.length > 0) {
        await this.insertTree(db, c.children, type, c.id);
      }
    }
  }

  private async seedBills(db: relationalStore.RdbStore): Promise<void> {
    const now: Date = new Date();
    const at = (daysAgo: number, h: number, m: number): number => {
      return new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysAgo, h, m, 0).getTime();
    };

    const seeds: SeedBill[] = [];
    seeds.push(new SeedBill('expense', 9900, 'canyin', '', '午餐·牛肉面', at(0, 12, 30), '现金', 'pending'));
    seeds.push(new SeedBill('expense', 1200, 'jiaotong', '', '地铁通勤', at(1, 8, 45), '微信钱包', 'none'));
    seeds.push(new SeedBill('expense', 7498, 'gouwu', '', '生活用品', at(2, 19, 20), '招商银行卡', 'none'));
    seeds.push(new SeedBill('expense', 3200, 'canyin', '', '咖啡下午茶', at(3, 15, 10), '微信钱包', 'none'));
    seeds.push(new SeedBill('expense', 8800, 'yule', '', '电影票', at(4, 20, 5), '微信钱包', 'none'));
    seeds.push(new SeedBill('expense', 5000, 'tongxun', 'tongxun_huafei', '话费充值', at(5, 10, 0), '微信钱包', 'refund'));
    seeds.push(new SeedBill('income', 26700, 'jianzhi', '', '周末兼职', at(7, 17, 30), '微信钱包', 'none'));
    seeds.push(new SeedBill('expense', 3790, 'jiaoyu', '', '在线课程', at(9, 21, 15), '招商银行卡', 'none'));
    seeds.push(new SeedBill('expense', 2600, 'jiaotong', '', '打车回家', at(10, 23, 5), '微信钱包', 'none'));
    seeds.push(new SeedBill('expense', 12800, 'canyin', '', '同事聚餐', at(11, 18, 40), '招商银行卡', 'pending'));
    seeds.push(new SeedBill('expense', 15600, 'yiliao', '', '感冒买药', at(13, 9, 50), '现金', 'none'));
    seeds.push(new SeedBill('expense', 10000, 'zhufang', '', '房屋水电', at(16, 11, 0), '招商银行卡', 'none'));
    seeds.push(new SeedBill('expense', 32900, 'gouwu', '', '换季衣服', at(21, 16, 25), '招商银行卡', 'none'));
    seeds.push(new SeedBill('income', 200000, 'jiangjin', '', '项目奖金', at(27, 10, 30), '招商银行卡', 'none'));
    seeds.push(new SeedBill('expense', 9900, 'canyin', '', '朋友聚会火锅', at(33, 12, 20), '微信钱包', 'none'));
    seeds.push(new SeedBill('income', 800000, 'gongzi', '', '上月工资', at(41, 9, 0), '招商银行卡', 'none'));
    seeds.push(new SeedBill('expense', 4500, 'canyin', '', '早餐豆浆油条', at(48, 7, 40), '现金', 'none'));
    seeds.push(new SeedBill('income', 35000, 'touzi', '', '基金收益', at(55, 14, 0), '招商银行卡', 'none'));

    for (let i: number = 0; i < seeds.length; i++) {
      const s: SeedBill = seeds[i];
      const v: relationalStore.ValuesBucket = {
        'bookId': 1,
        'type': s.type,
        'amount': s.amount,
        'categoryId': s.categoryId,
        'subId': s.subId,
        'remark': s.remark,
        'occurTime': s.occurTime,
        'account': s.account,
        'tags': s.refund === 'pending' ? '["报销"]' : '[]',
        'excludeStat': 0,
        'refundStatus': s.refund
      };
      await db.insert('bill', v);
    }
  }

  private async loadAll(): Promise<void> {
    await this.loadBooks();
    await this.loadCategories();
    await this.loadAccounts();
    await this.loadBills();
  }

  private async loadBooks(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const rs: relationalStore.ResultSet = await db.querySql('SELECT id, name, budget FROM book ORDER BY id', []);
    const list: Book[] = [];
    while (rs.goToNextRow()) {
      list.push(new Book(rs.getLong(0), rs.getString(1), rs.getLong(2)));
    }
    rs.close();
    this.books = list;
  }

  private async loadCategories(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const rs: relationalStore.ResultSet =
      await db.querySql('SELECT id, name, icon, color, bg, type, parentId FROM category', []);
    const rows: CatRow[] = [];
    while (rs.goToNextRow()) {
      rows.push(new CatRow(rs.getString(0), rs.getString(1), rs.getString(2),
        rs.getString(3), rs.getString(4), rs.getString(5), rs.getString(6)));
    }
    rs.close();
    const roots: Category[] = [];
    for (let i: number = 0; i < rows.length; i++) {
      const r: CatRow = rows[i];
      if (r.parentId === '') {
        roots.push(new Category(r.id, r.name, r.icon, r.color, r.bg, r.type as BillType));
      }
    }
    for (let i: number = 0; i < roots.length; i++) {
      const root: Category = roots[i];
      for (let j: number = 0; j < rows.length; j++) {
        const r: CatRow = rows[j];
        if (r.parentId === root.id) {
          root.children.push(new Category(r.id, r.name, r.icon, r.color, r.bg, r.type as BillType));
        }
      }
    }
    this.categories = roots;
  }

  private async loadAccounts(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const rs: relationalStore.ResultSet =
      await db.querySql('SELECT id, name, icon, type, balance, hidden FROM account ORDER BY id', []);
    const list: AssetAccount[] = [];
    while (rs.goToNextRow()) {
      const acc: AssetAccount = new AssetAccount(rs.getLong(0), rs.getString(1), rs.getString(2),
        rs.getString(3) as AccountType, rs.getLong(4));
      acc.hidden = rs.getLong(5) !== 0;
      list.push(acc);
    }
    rs.close();
    this.accounts = list;
  }

  private async loadBills(): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const rs: relationalStore.ResultSet = await db.querySql(
      'SELECT id, bookId, type, amount, categoryId, subId, remark, occurTime, account, tags, excludeStat, refundStatus ' +
      'FROM bill ORDER BY occurTime DESC, id DESC', []);
    const list: Bill[] = [];
    while (rs.goToNextRow()) {
      const b: Bill = new Bill();
      b.id = rs.getLong(0);
      b.bookId = rs.getLong(1);
      b.type = rs.getString(2) as BillType;
      b.amount = rs.getLong(3);
      b.categoryId = rs.getString(4);
      b.subId = rs.getString(5);
      b.remark = rs.getString(6);
      b.occurTime = rs.getLong(7);
      b.account = rs.getString(8);
      b.tags = this.parseTags(rs.getString(9));
      b.excludeStat = rs.getLong(10) !== 0;
      b.refundStatus = rs.getString(11) as RefundStatus;
      list.push(b);
    }
    rs.close();
    this.bills = list;
  }

  private parseTags(raw: string): string[] {
    try {
      const parsed: object = JSON.parse(raw) as object;
      if (Array.isArray(parsed)) {
        const out: string[] = [];
        for (let i: number = 0; i < parsed.length; i++) {
          const el: Object = parsed[i];
          if (typeof el === 'string') {
            out.push(el);
          }
        }
        return out;
      }
    } catch (err) {
      return [];
    }
    return [];
  }

  async addBill(bill: Bill): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const v: relationalStore.ValuesBucket = {
      'bookId': bill.bookId,
      'type': bill.type,
      'amount': bill.amount,
      'categoryId': bill.categoryId,
      'subId': bill.subId,
      'remark': bill.remark,
      'occurTime': bill.occurTime,
      'account': bill.account,
      'tags': JSON.stringify(bill.tags),
      'excludeStat': bill.excludeStat ? 1 : 0,
      'refundStatus': bill.refundStatus
    };
    const id: number = await db.insert('bill', v);
    bill.id = id;
    this.bills.unshift(bill);
    this.bills.sort((a: Bill, b: Bill): number => b.occurTime - a.occurTime);
    this.emitChange();
  }

  async deleteBills(ids: number[]): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const pred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('bill');
    pred.in('id', ids);
    await db.delete(pred);
    this.bills = this.bills.filter((b: Bill): boolean => !ids.includes(b.id));
    this.emitChange();
  }

  async addBook(name: string, budget: number): Promise<Book> {
    const db: relationalStore.RdbStore = this.rdb!;
    const v: relationalStore.ValuesBucket = {
      'name': name,
      'budget': budget
    };
    const id: number = await db.insert('book', v);
    const bk: Book = new Book(id, name, budget);
    this.books.push(bk);
    this.emitChange();
    return bk;
  }

  async renameBook(id: number, name: string): Promise<void> {
    const db: relationalStore.RdbStore = this.rdb!;
    const pred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('book');
    pred.equalTo('id', id);
    const v: relationalStore.ValuesBucket = {
      'name': name
    };
    await db.update(v, pred);
    for (let i: number = 0; i < this.books.length; i++) {
      if (this.books[i].id === id) {
        this.books[i].name = name;
      }
    }
    this.emitChange();
  }

  async deleteBook(id: number): Promise<void> {
    if (this.books.length <= 1) {
      return;
    }
    const db: relationalStore.RdbStore = this.rdb!;
    const pred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('book');
    pred.equalTo('id', id);
    await db.delete(pred);
    this.books = this.books.filter((b: Book): boolean => b.id !== id);
    this.emitChange();
  }

  emitChange(): void {
    emitter.emit({ eventId: EVT_DATA_CHANGED });
  }
}

export class SeedBill {
  type: string = 'expense';
  amount: number = 0;
  categoryId: string = '';
  subId: string = '';
  remark: string = '';
  occurTime: number = 0;
  account: string = '现金';
  refund: string = 'none';

  constructor(type: string, amount: number, categoryId: string, subId: string,
    remark: string, occurTime: number, account: string, refund: string) {
    this.type = type;
    this.amount = amount;
    this.categoryId = categoryId;
    this.subId = subId;
    this.remark = remark;
    this.occurTime = occurTime;
    this.account = account;
    this.refund = refund;
  }
}

export class CatRow {
  id: string = '';
  name: string = '';
  icon: string = '';
  color: string = '';
  bg: string = '';
  type: string = '';
  parentId: string = '';

  constructor(id: string, name: string, icon: string, color: string, bg: string, type: string, parentId: string) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.color = color;
    this.bg = bg;
    this.type = type;
    this.parentId = parentId;
  }
}
