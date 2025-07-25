# code-server简介
## code-server：运行在浏览器上的VSCode。

自VSCode发布以来，VSCode就受到了广大程序员的青睐。VSCode丰富的插件能够满足使用者各色各样的需求。但VSCode使用受限于图形化界面的需求，只能安装在客户端而不能安装在服务器上。code-server的出现完美的解决了VSCode不能安装在服务端的缺陷。

code-server是一款运行在浏览器界面上的可以安装在任何机器上的VSCode程序，code-server不仅继承了VSCode的使用逻辑，丰富的插件，在VSCode的基础上还提供了更多VSCode所没有的特性，满足更多的使用场景和业务需求。

## code-server具有以下特性：

- 绿色安装：code-server可以通过压缩包解压运行，不需要直接安装，相比软件包安装的方式更加绿色
- 一次部署，终身开箱即用：每次安装完VSCode后，都需要重新进行VSCode的相关配置，安装插件。code-server由于其绿色安装的特性，可以将相关配置和插件安装在指定路径，这样在机器中需要code-server时，只需要拷贝运行即可，不需要在额外安装插件，进行软件配置
- 服务器部署，容器集成：code-server只需要部署后，其他任何能够访问到部署机器的地方都可以通过code-server访问服务，相比传统IDE，更容易集成进服务器和容器内进行开发
- 端口转发：code-server相比传统IDE和VSCode，自带有端口转发功能。通过code-server，在服务器因防火墙或容器内等开放端口受限等情况下，自动代理转发服务，减少额外的端口开放操作。