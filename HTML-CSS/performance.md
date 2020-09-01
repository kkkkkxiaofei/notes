### 1. 关键路径分析

`DCL`: DOMContentLoaded事件，DOM构建完成就会触发。

`L`: onload事件，外部依赖资源下载完成后会触发。

`Parse HTML`: html文件请求后，开始分析html（词法，token..)，而后构建DOM，此过程完毕后DOM构建则完成。由于DOM的构建会受到其他外部依赖影响，但它并不是一次完成，有可能分段。

`Reclaculate Style`: 构建CSSOM。

`Layout`: 利用render tree进行重排。

`Paint`: layout后的结果进行重绘。

`Composite Layer`：组合层。

- demo1: pure html

```
<!DOCTYPE html>
<html>
<head>
	<title>pure html</title>
</head>
<body>
	<h1>performance for pure html</h1>
</body>
</html>
```

performance:

![](/images/performance/1-1.png)

由于没有任何依赖（js，css，image..)整个关键路径很短，所以DCL和L的事件很接近。

为了看清楚DCL和L之间的差别， 我们可以加载一个图片。

- demo2: html + img 

```
<!DOCTYPE html>
<html>
<head>
	<title>pure html</title>
</head>
<body>
	<h1>performance for pure html</h1>
	<img src="https://cdn.zeplin.io/5ce3a5cd01603b1d7a1ff379/screens/25EAB469-7FB0-4751-AF93-711ED3EC3359.png">
</body>
</html>
```
 performance：

![](/images/performance/1-2.png)

为了将差异放大，我特意挑选了比较大的图片（4.1M)，可以看到，DCL时间和demo1相比差别不大，但是由于L事件需要等待图片加载，因此大概用了近5秒才触发。

- demo3: html + img + css

既然img会影响L，那么同理css也会；但css对DCL有影响吗？

```
<!DOCTYPE html>
<html>
<head>
	<title>pure html</title>
	<link rel="stylesheet" type="text/css" href="/style.css">
</head>
<body>
	<h1>performance for pure html</h1>
</body>
</html>
```

performance：

![](/images/performance/1-3.png)

可以看到，外部css依然不会影响DCL（并不会影响DOM)。由于有外部style文件，因此需要解析(Parse Stylesheet)，这就会导致重新构建CSSOM，于是构建完成后才会构建渲染树(render tree需要DOM+CSSOM），这就是外部style影响L事件的根本原因。

- demo4: html + img + css + js

index.html

```
<!DOCTYPE html>
<html>
<head>
	<title>pure html</title>
</head>
<body>
	<h1>performance for pure html</h1>
	<script src="/index.js" ></script>
</body>
</html>
```

index.js

```
var h1 = document.getElementsByTagName('h1')[0];
h1.textContent = 'changed by js'; // 1 
h1.style.display = 'inline';  // 2
// 3
var newElement = document.createElement('div');
newElement.textContent = 'You loaded this page on: ' + new Date();
newElement.style.color = 'blue';
document.body.appendChild(newElement);
```

performance：

![](/images/performance/1-4.png)

之前总有个误区，认为L事件一定是在DCL事件后面边的，但实际上L事件只代表页面所有外部资源加载完成，而DCL只关注DOM是否构建完成，两者其实是不同的纬度，所以L是可以在DCL之前的。

在L的左边最近一处的黄色片段就是`index.js`，它的执行直接导致了DOM和CSSDOM的改变，因此需要经历(L和DCL的间隙处)`Parse HTML -> Recalculate Style -> Layout`之后才能触发DCL。

很明显，外部js脚本是最影响页面加载的资源了，因此可以用async：

```
<script src="/index.js" async></script>
```

![](/images/performance/1-5.png)

很明显，async可以让js脚本不阻塞DOM构建，因此DCL在L之前。



