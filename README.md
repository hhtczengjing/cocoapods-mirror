# cocoapods-mirror

使用私有镜像对CocoaPods访问速度进行优化，后续会做cocoapods pod自动生成静态库优化

### Usage

#### (1)安装gem依赖

```
bundle install
```

#### (2)修改podspec文件

```
rake "clone[WebViewJavascriptBridge]" 
```

#### （3)使用gitmirror克隆项目

```
rake "mirror[https://github.com/AFNetworking/AFNetworking.git]" 
```
