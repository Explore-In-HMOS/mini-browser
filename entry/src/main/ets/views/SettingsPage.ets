import { WebDataManager } from '../common/WebDataManager';
import { BrowserSession } from '../model/BrowserSession';

@Component
export struct SettingsPage {
  private toast(ok: boolean): void {
    this.getUIContext().getPromptAction().showToast({
      message: ok ? $r('app.string.settings_done') : $r('app.string.settings_failed')
    });
  }

  @Builder
  actionRow(icon: Resource, label: Resource, action: () => void) {
    ListItem() {
      Row({ space: 13 }) {
        Image(icon)
          .width(20)
          .height(20)
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.primary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width(236)
      .height(58)
      .padding({ left: 18, right: 18 })
      .borderRadius(29)
      .backgroundColor($r('app.color.card_background'))
      .border({ width: 1, color: $r('app.color.surface_border') })
      .onClick(action)
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.settings_title'))
          .fontFamily('HarmonyOS Sans Mono, monospace')
          .fontSize($r('app.float.section_label_font_size'))
          .letterSpacing(3)
          .fontColor($r('app.color.reader_dim_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 14 })

        List({ space: 10 }) {
          this.actionRow($r('app.media.ic_cookie'), $r('app.string.settings_clear_cookies'), () => {
            this.toast(WebDataManager.clearCookies());
          })
          this.actionRow($r('app.media.ic_storage'), $r('app.string.settings_clear_storage'), () => {
            this.toast(WebDataManager.clearDomStorage());
          })
          this.actionRow($r('app.media.ic_history_red'), $r('app.string.settings_clear_history'), () => {
            const controller = BrowserSession.getController();
            this.toast(controller ? WebDataManager.clearHistory(controller) : false);
          })
          this.actionRow($r('app.media.ic_cache'), $r('app.string.settings_clear_cache'), () => {
            const controller = BrowserSession.getController();
            this.toast(controller ? WebDataManager.clearCache(controller) : false);
          })
          this.actionRow($r('app.media.ic_database'), $r('app.string.settings_clear_database'), () => {
            this.toast(WebDataManager.clearWebDatabase());
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ top: 4, bottom: 20 })
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
  }
}
