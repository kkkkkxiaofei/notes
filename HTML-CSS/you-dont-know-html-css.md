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

物理像素很好理解，就是设备本身用来表示图像的最小单位，它代表屏幕横向和纵向分别能容纳多少个图像单位（点）。

以iphone7为例子，它的尺寸为4.7英寸（对角线），宽高分别为2.3和4.1，它的分辨率为750*1334，而如果我们查看chrome模拟器发现iphone7的尺寸为375*667

这里750*1334即为物理像素，而375*667为逻辑像素（设备独立像素dip)

 *** 为什么不让物理像素等于逻辑像素呢？***

试想想如果两者相等，那么开发软件时我们css设置px将严格等于设备，100px等于100px，那如果我们的软件要放在更高的物理像素的设备上运行呢，自然就会变小。因此才有逻辑像素这个概念，软件在和真实设备交互时，用的是逻辑像素，因此同样的1px，对应到真实设备上的像素个数自然不一样。

物理像素和设备独立像素的比例叫做dpr， 这个比例决定了换算关系：

```
dpr = 物理像素/设备独立像素(dip)
```

`dpr`可以用`window.devicePixelRatio`查看, iphone7的dpr为2，即我们写的css里的1px * 1px在真实手机里其实是2px * 2px，即1单位像素的css方块，对应在真实的设备里是4个像素，因此就会有移动端内1px显示较为粗的问题。 

*** 另外，设备分辨率和清晰度是没有直接关系的，是不是很反直觉？***

比如上面750*1334分辨率，我可以放在4.7手机上，自然也可以放在51寸的小米电视上（后者一定不清晰），因此单纯比较分辨率没有意义。

那清晰度到底拿什么衡量呢？这就是ppi（pixels per inch)的概念：

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

### 5. flex

`block`默认占父元素宽度，一行一个，高度可设置；`inline`元素，如img，span等无法设置高度，高度完全有内容撑开，但兄弟节点会按照一行排列。

因此出现了`inline-block`，既能设置高度，又可排列在一行。

`flex`和`inline-flex`也是如此，他们唯一的区别就是后者做为flex的容器，在兄弟节点上是行内元素的效果，即排列成一行。

#### 5.1 基本属性

- flex容器的属性

`flex-direction`: 默认为`row`，方向决定了主轴的方向。

`flex-wrap`: 默认为`nowrap`，即所有item会一直会挤在一行内。

`flex-flow` `flex-direction`和`flex-wrap`的缩写，默认为`row nowrap`

`justify-content`: 主轴方向item的对齐方式。

`align-items`:辅轴方向item的对齐方式。

`align-content`: 又多个轴线时（多个flex容器），它们做为整体，在***辅轴***上的对齐方式。

- item子项的属性

`order`: 默认为0，数值越小优先级越大。

`flex-grow`: 放大比例（若有剩余空间），默认为0，即不放大。

`flex-shrink`: 缩小比例（若空间不足），默认为1。

`flex-basis`: 定义子项目的初始主轴大小，默认为auto。默认下，子项的主轴大小是容器的大小，这样根据grow/shrink的值就能计算出该子项的最终大小。

`flex`: `flex-grow flex-shrink? flex-basis`，默认值为`0 1 auto`。

`align-self`: 覆盖容器的`align-item`排列，说明子项有自定义的对齐方式。

九宫格例子：

```
<div class="flex-container">
  <div class="flex-item">1</div>
  <div class="flex-item">2</div>
  <div class="flex-item">3</div>
  <div class="flex-item">4</div>
  <div class="flex-item">5</div>
  <div class="flex-item">6</div>
  <div class="flex-item">7</div>
  <div class="flex-item">8</div>
  <div class="flex-item">9</div>
</div>

.flex-container {
  display: flex;
  justify-content: center;
  flex-flow: wrap-reverse;
}

.flex-item {
  flex: 0 0 33%;
  background: #ccc;
  text-align: center;
}
```

#### 5.2 兼容性

全浏览器兼容，IE下版本要求较高。

### 6. grid

`flex`是一纬的，基本都是针对主轴的设置；`grid`则是二纬的，有了行和列之分，因此布局上会有单元格的概念，适合较为复杂的页面主题布局。

#### 6.1 容器属性

`display`: `grid`和`inline-grid`，不解释，区别与`flex/inline-flex`类似。

`grid-template-columns/rows`: 定义列模版，使用较为灵活，如下。

```
grid-template-columns: 100px 1fr;
grid-template-columns: 100px 100px 100px;
grid-template-columns: repeat(10, 1fr);
grid-template-columns: repeat(auto-fill, 100px);

```

ps: 这里`auto-fill`类似`flex-basis`。

`grid-gap`: 其实是 `<grid-row-gap> | <grid-column-gap>`的缩写。

`justify-content`: 与`flex`的`justify-content`类似，代表子项作为整体，在容器内水平方向的对其方式。

`align-content`: 与`flex`的`align-items`类似，代表子项作为整体，在容器内垂直方向的对其方式。





