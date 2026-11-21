import { BillType, Category } from './Models';

export class CategoryData {
  static buildExpenseTree(): Category[] {
    const list: Category[] = [];
    list.push(new Category('canyin', '餐饮', 'fork_knife', '#FF7D47', '#1AFF7D47', 'expense'));
    list.push(new Category('jiaotong', '交通', 'car', '#4A90E2', '#1A4A90E2', 'expense'));
    list.push(new Category('gouwu', '购物', 'bag', '#E857A0', '#1AE857A0', 'expense'));
    list.push(new Category('zhufang', '住房', 'house', '#9C6CD6', '#1A9C6CD6', 'expense'));
    list.push(new Category('yule', '娱乐', 'game', '#34C3A2', '#1A34C3A2', 'expense'));
    list.push(new Category('yiliao', '医疗', 'cross_case', '#F5453C', '#1AF5453C', 'expense'));
    list.push(new Category('jiaoyu', '教育', 'graduationcap', '#3D7BFA', '#1A3D7BFA', 'expense'));
    const tongxun: Category =
      new Category('tongxun', '通讯', 'phone', '#0EC26C', '#1A0EC26C', 'expense');
    tongxun.children.push(new Category('tongxun_huafei', '话费', 'phone', '#0EC26C', '#1A0EC26C', 'expense'));
    tongxun.children.push(new Category('tongxun_wangfei', '网费', 'wifi', '#0EC26C', '#1A0EC26C', 'expense'));
    list.push(tongxun);
    list.push(new Category('other_exp', '其他支出', 'ellipsis_circle', '#9AA0A6', '#1A9AA0A6', 'expense'));
    return list;
  }

  static buildIncomeTree(): Category[] {
    const list: Category[] = [];
    list.push(new Category('gongzi', '工资', 'coins', '#3D7BFA', '#1A3D7BFA', 'income'));
    list.push(new Category('jiangjin', '奖金', 'medal', '#FAAD14', '#1AFAAD14', 'income'));
    list.push(new Category('touzi', '投资', 'diamond', '#9C6CD6', '#1A9C6CD6', 'income'));
    list.push(new Category('jianzhi', '兼职', 'briefcase', '#0EC26C', '#1A0EC26C', 'income'));
    list.push(new Category('other_inc', '其他收入', 'ellipsis_circle', '#9AA0A6', '#1A9AA0A6', 'income'));
    return list;
  }

  static findCategory(roots: Category[], id: string): Category {
    for (let i: number = 0; i < roots.length; i++) {
      const root: Category = roots[i];
      if (root.id === id) {
        return root;
      }
      for (let j: number = 0; j < root.children.length; j++) {
        const child: Category = root.children[j];
        if (child.id === id) {
          return child;
        }
      }
    }
    return roots.length > 0 ? roots[roots.length - 1] : new Category('other', '其他', 'ellipsis_circle', '#9AA0A6', '#1A9AA0A6', 'expense');
  }

  static treeOf(roots: Category[], type: BillType): Category[] {
    return roots.filter((c: Category): boolean => c.type === type);
  }
}
