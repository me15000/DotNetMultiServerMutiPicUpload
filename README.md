#DotNetMultiServerUpload

## 简介 ##

此程序为图片上传程序，需要windows IIS .net 运行环境

windows server 2008  r2

.net framework 4.5

iis 7.5


支持多图片上传，多服务器备份

## 使用场景 ##

图片服务器有几十个GB的图片

服务器有很多不稳定因素，

如：

硬盘会坏掉

机房会断电

白名单会丢失

……

当发生上述情况的时候再去迁移服务器，就很困难

这些问题都可能导致图片服务器无法访问的窘境，

为了增强用户体验，就要考虑到上述问题，对图片做好实时备份

**DotNetMultiServerUpload** 就是专门为解决这些问题而诞生


## 使用说明 ##


**需要的硬件环境**


- 一台图片服务器	（主）（master） 
- 一台图片备份服务器	  （backup）
- 两台服务器均为 windows 2008 r2 iis .net framework 4.5 环境



**部署环境**


【第一步】

分别在 主服务器 和 备份服务器上建立 一个站点


并绑定域名 i-1.xx.com 把站点命名为 i-1.xx.com （根据需要绑定你自己的域名）

同时 在主服务器 站点 i-1.xx.com 上再绑定一个域名 s1.i-1.xx.com
	
在备份服务器站点 i-1.xx.com 上再绑定一个域名 s2.i-1.xx.com


在域名管理系统里面把域名解析至对应服务器

s1.i-1.xx.com 绑定至主服务器
s2.i-1.xx.com 绑定至备份服务器
i-1.xx.com 绑定至主服务器


如果主服务器出现故障，就把域名（i-1.xx.com）再解析至备份服务器 


【第二步】

把程序放置在两台服务器 站点i-1.xx.com 下面，修改配置文件 /web.config 和 /servers.xml.config

/web.config


	<?xml version="1.0"?>
	<!--
	  有关如何配置 ASP.NET 应用程序的详细信息，请访问
	  http://go.microsoft.com/fwlink/?LinkId=169433
	  -->
	<configuration>
	  <appSettings>

		<!--当前服务器名称 对应 servers.xml.config-->
		<add key="ServerName" value="s1"/>
		
		
		<!--备份服务器列表配置文件-->
		<add key="Servers" value="/servers.xml.config"/>
		
		<!--当前服务器安全密钥-->
		<add key="SecurityKey" value="asdfdsfsdf"/>
		
		<!--日志所在目录-->
		<add key="Log" value="/log"/>
		
	  
		<!--当前服务器域名-->
		<add key="Domain" value="http://i-1.xx.com"/>
	  </appSettings>
	  <!--
		有关 .NET 4.5 的 web.config 更改的说明，请参见 http://go.microsoft.com/fwlink/?LinkId=235367。

		可在 <httpRuntime> 标记上设置以下特性。
		  <system.Web>
			<httpRuntime targetFramework="4.5" />
		  </system.Web>
	  -->
	  <system.web>
		<customErrors mode="Off"/>
		<compilation debug="true" targetFramework="4.5"/>
		<pages controlRenderingCompatibilityVersion="4.0"/>
	  </system.web>
	</configuration>



/servers.xml.config

	<?xml version="1.0" encoding="utf-8" ?>
	
	<Servers>
	  <!--备份服务器1-->
	  <Server Name="s1" Uri="http://s1.i-1.upload.xx.com/do.ashx" SecurityKey="asdfdsfsdf" />
	
	  <!--备份服务器2-->
	  <Server Name="s2" Uri="http://s2.i-1.upload.xx.com/do.ashx" SecurityKey="asdfdsfsdf" />
	</Servers>



## 程序说明 ##

整套程序分为几个部分

1. 后台多图上传程序 /.m/upload.aspx
1. 核心程序 /do.ashx


部署好程序之后，就可以通过地址 http://i-1.xx.com/.m/upload.aspx?SecurityKey=asdfdsfsdf 去上传图片 

或 http://s1.i-1.xx.com/.m/upload.aspx?SecurityKey=asdfdsfsdf 上传图片
或 http://s2.i-1.xx.com/.m/upload.aspx?SecurityKey=asdfdsfsdf 上传图片

无论使用哪个地址，程序都会自动把图片合并同步至另外的服务器上面

当然在合并同步另外的服务器的时候 也可能会遇到 网络问题或服务器问题，导致同步失败的可能

这种情况 **DotNetMultiServerUpload** 是考虑到的，当出现上述问题导致同步失败的时候，

程序就会创建 日志文件，记录上传失败的文件信息和服务器信息，

可以在服务器端制定一个计划任务，定期的去处理错误


定期去执行这两个地址，就可以把上传失败的文件再次同步至其他服务器

http://s1.i-1.xx.com/do.ashx?action=uploaderrors&SecurityKey=asdfdsfsdf

http://s2.i-1.xx.com/do.ashx?action=uploaderrors&SecurityKey=asdfdsfsdf


## 第三方程序接口 ##

上传可以通过 /.m/upload.aspx 去上传

也可以接入至其他后台中

只需把图片上传至

http://i-1.xx.com/do.ashx?action=upload&SecurityKey=asdfdsfsdf

即可

如C#代码实现：

        string SecurityKey = "asdfdsfsdf";
        string format = "xml"; //or json 

        WebClient wc = new WebClient();
        byte[] data = wc.UploadFile("http://i-1.xx.com/do.ashx?action=upload&format=" + format + "&SecurityKey=" + SecurityKey, @"D:\xx.jpg");
        wc.Dispose();

        string xml = System.Text.Encoding.GetEncoding("utf-8").GetString(data);
        /*
        返回成功结果：
        XML：
        <resp>
        <success>1</success>
        <link>http://i-1.xx.com/2014/4/15/5310bcaf-0f8a-45c5-9a61-9bf45b5e09c1.jpg</link>
        </resp>

    
        JSON：   
        {"resp":{"success":1,"link":"http://i-1.xx.com/2014/4/15/5310bcaf-0f8a-45c5-9a61-9bf45b5e09c1.jpg"}}         
        */
