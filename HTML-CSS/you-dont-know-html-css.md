### 1.disabled and readonly

`disabled`: 不能编辑，不能focus，表达发送时不会发送，事件也无法trigger

`readonly`: 仅仅只是不能编辑

### 2.pseudo class vs pseudo element

`pseudo class`: 单引号，常见的:first-child, :focus...

`pseudoe element`: 双引号 如::first-line, ::before , ::after

### 3. z-index层叠关系

![](/images/css/6.png)

html结构如下：

```
div1
  div2 
  div3
    div4
    div5
      div6  
```

为了简单起见，所有div都是position: relative，渲染结果：

```
#div1 50
  #div2 40
  #div3 30
    #div5 10
      #div6 100
    #div4 60
```

有z-index默认层叠顺序为由上到下，由外到内，子节点永远不能高于父节点;

但是若父节点没有设置z-index,则父节点在进行比较时会使用子节点中最大的z-index，所以极端情况下，若想让最深层级的叶子节点具有最高层叠优先级，则需要由上而下依次清除路径中的z-index。

一般的层叠顺序由高到低依次为：

```
z-index正值 > z-index为0/auto > inline/inline-block > float > block > z-index为负值 > border/background
```
### 4. viewport

#### 4.1 css里的1px不等于一个像素

css里的px是一个虚拟的概念，它不是能代表设备的物理像素，但是我们可以查看`window.devicePixelRatio`(dpr)，

```
dpr = 物理像素/设备独立像素(dip)
```

物理像素很好理解，就是设备本身用来表示图像的最小单位，它代表屏幕横向和纵向分别能容纳多少个图像单位（点）。

以iphone7为例子，它的尺寸为4.7英寸（对角线），宽高分别为2.3和4.1，它的分辨率为750*1334

而如果我们查看chrome模拟器发现iphone7的尺寸为375*667

这里750*1334即为物理像素，而375*667为逻辑像素（dip)

为什么不让物理像素等于逻辑像素呢？

试想想如果两者相等，那么开发软件时我们css设置px将严格等于设备，100px等于100px，那如果我们的软件要放在更高的物理像素的设备上运行呢，自然就会变小。因此才有逻辑像素这个概念，软件在和真实设备交互时，用的是逻辑像素，因此同样的1px，根据不同的dpr，对应到真实设备上的像素个数自然不一样。

iphone7的dpr为2，即我们写的css里的1px * 1px在真实手机里其实是2px * 2px，即1单位像素的css方块，在对应在真实的设备里是4个像素。 

另外，设备分辨率和清晰度是没有直接关系的，是不是很反直觉？

比如上面750*1334分辨率，我可以放在4.7手机上，自然也可以放在51寸的小米电视上，后者一定不清晰。

这里还有ppi（pixels per inch)的概念,

```
ppi(iphone7) = 分辨率/尺寸 = 750/2.3 = 1334/4.1 = 326
```

因此ppi的大小才决定了设备显示的清晰度。




#### 4.2 三种视窗

`layout view`: 为了让桌面端和手机端都能显示网页，就得有一个视窗容纳这两种场景，它可以用`document.documentElement.clientWidth`来获取`layout view`, 它往往比浏览器得可是区域要大。

`visual view`: 浏览器得可视区域，`window.innerWidth`(不含滚动条)

`ideal view`: 理想视窗，无论物理设备多大，都无差异的显示，它的尺寸由不同的设备决定，比如`iphone`的理想视窗就是320px。

#### 4.3 viewport参数

```
<meta name="viewport" content="width=device-width, initial-scale=1.0">

```

这里的width代表的是`layout view`，`device-width`代表`ideal view`，这就是说浏览器的视窗和设备理想视窗一样大，这样我们用手机看的时候就不会出现字体很小或者有滚动条的情况。

`initial-scale`的缩放比例指的是`ideal view`的比例，因此比例为1依然能达到`device-width`的效果。

*** 那么两者有什么区别呢？ ***

两者都能实现同样的效果，但是两者各自单独使用时都有一个bug：
`initial-scale=1`会导致win phone和IE无论横竖屏都把宽度设为`ideal view`;`width=device-width`则会导致iphone和ipad上有同样的问题。

那如果两个设置了冲突的值呢？

```
<meta name="viewport" content="600, initial-scale=1.0">
```

谁大用谁。

因此，最佳方案就是两个一起写。即：

```
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

[参考](https://www.cnblogs.com/2050/p/3877280.html)