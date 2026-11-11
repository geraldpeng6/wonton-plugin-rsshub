# shellcheck shell=bash
# RSSHub 的冒烟探测。
#
# 首页是路由文档页；RSSHub 没有账号体系（sso: none，网关把守），身份项记 N/A；
# 数据只放在内存缓存里，没有用户数据，数据两项记 N/A。
# 网页项除了断言真实页面，还经网关请求一条要出网的路由 /rsshub/routes（上游抓
# docs.rsshub.app/routes.json 后生成 RSS），断言返回 RSS XML：把网关、应用和出网代理一起验掉。
# 选它当冒烟路由是因为它稳定、不要 Cookie；GitHub 路由未配令牌时会被限流，不拿来做冒烟。
# ACCESS_KEY 开着时路由都要带 ?key=，从容器环境里取核心生成的值。
export IDENTITY_NA=1
export DATA_NA=1
export SMOKE_NOTE="RSSHub 没有账号体系：网页靠网关会话把守，订阅靠插件密钥里的 ACCESS_KEY"

web_assert() { # 标准输入：插件首页 HTML
  grep -qi 'rsshub' || { echo "首页没有 RSSHub 特征"; return 1; }
  local key rss
  key="$(docker exec "wonton-$SMOKE_INSTANCE--$SMOKE_SLUG--rsshub" printenv ACCESS_KEY 2>/dev/null)" ||
    { echo "容器里取不到 ACCESS_KEY"; return 1; }
  rss="$(web_get "/rsshub/routes?key=$key")" ||
    { echo "/rsshub/routes 请求失败：$(head -c 200 <<<"$rss")"; return 1; }
  grep -qi '<rss\|<?xml' <<<"$rss" ||
    { echo "/rsshub/routes 没有返回 RSS XML：$(head -c 200 <<<"$rss")"; return 1; }
}
