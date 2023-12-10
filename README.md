
## 说明
本项目用于导出备份微信的聊天记录，不依赖微信的客户端使用，做到离线且永久保存。
解决大部分人因为微信的聊天记录内存飞快增长而已束手无策的烦恼。<img src="resource/old_man_phone.png" width="30" height="30" alt="无法加载">

项目基于 [wechat-backup](https://github.com/greycodee/wechat-backup) 修改。
主要优化了前端的浏览功能，如按照关键字查找聊天记录、按照日期查看、查看图片与视频等功能。
本项目期望后续做到小白可以直接使用，欢迎大家积极提问和使用！

## 效果图
![](resource/wechat.gif)

## 使用流程
> 详细说明在: [解密安卓微信聊天信息存储](https://blog.greycode.top/posts/android-wechat-bak/)
> 需要准备一台有ROOT权限的手机或者使用安卓模拟器
> 需要一个Linux环境，golang环境，docker环境（可选）
> 目前使用需要一定的Linux基础知识，后续持续迭代会让操作小白化

1. 使用微信的 [聊天记录迁移](https://kf.qq.com/touch/faq/180122ua6NB7180122zI3AZR.html) 功能，将需要备份的聊天记录迁移到有ROOT权限的手机上。

2. 将你的PC使用 `adb` 连接上你的手机或者安卓虚拟机。
```shell
git cloen https://github.com/git-jiadong/wechat-backup.git
# 导出聊天记录
bash ./wechat_export.sh
# 编译程序
go build .
# 启动程序
./wechat-backup -f export_dir/res/
```
3. 在浏览器输入 `http://localhost:9999` 即可查看聊天记录

> ~~注意⚠️：WxFileIndex.db 里面文数据表名老版本微信是 WxFileIndex2 ,新版本微信是 WxFileIndex3 ，请根据实际情况来设置代码 wxfileindex.go 文件中 SQL 查询的表名~~(已在代码中做处理)

## Q&A
### 程序编译出错
可能是你的golang版本太老，可以使用 `golang` 的版本管理器 [gvm](https://github.com/moovweb/gvm) 切换成大于等于`go1.17.13` 的版本即可

### 推荐安卓模拟器
可以使用逍遥模拟器，它可以和Windown的 `Hyper-v` 模式兼容，逍遥模拟器的 [adb端口](https://bbs.xyaz.cn/forum.php?mod=viewthread&tid=365537)

## 致谢
- [wechat-backup](https://github.com/greycodee/wechat-backup) 感谢大佬的贡献
- [silk-v3-decoder](https://github.com/kn007/silk-v3-decoder/tree/07bfa0f56bbfcdacd56e2e73b7bcd10a0efb7f4c) silk v3音频解码