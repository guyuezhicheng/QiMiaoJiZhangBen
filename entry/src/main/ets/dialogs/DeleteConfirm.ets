import { UIContext } from '@kit.ArkUI';
import { Theme } from '../model/Theme';

export class DeleteConfirm {
  static show(ui: UIContext, count: number, onConfirm: () => void): void {
    ui.showAlertDialog({
      title: '删除确认',
      message: `确定删除选中的 ${count} 条账单吗？删除后不可恢复。`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确认删除',
        fontColor: Theme.cRed,
        action: () => {
          onConfirm();
        }
      }
    });
  }
}
