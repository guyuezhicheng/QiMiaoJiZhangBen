import { AssetAccount } from '../model/Models';

export class AssetSummary {
  net: number = 0;
  assets: number = 0;
  liabilities: number = 0;
  borrowIn: number = 0;
  lendOut: number = 0;
  receivable: number = 0;
}

export class AssetCalc {
  static summary(accounts: AssetAccount[]): AssetSummary {
    const s: AssetSummary = new AssetSummary();
    for (let i: number = 0; i < accounts.length; i++) {
      const a: AssetAccount = accounts[i];
      if (a.balance >= 0) {
        s.assets += a.balance;
      } else {
        s.liabilities += -a.balance;
        s.borrowIn += -a.balance;
      }
    }
    s.net = s.assets - s.liabilities;
    s.receivable = 0;
    s.lendOut = 0;
    return s;
  }
}
