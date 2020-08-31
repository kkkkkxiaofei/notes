### 1.disabled and readonly

`disabled`: 不能编辑，不能focus，表达发送时不会发送，事件也无法trigger

`readonly`: 仅仅只是不能编辑

### 2.pseudo class vs pseudo element

`pseudo class`: 单引号，常见的:first-child, :focus...

`pseudoe element`: 双引号 如::first-line, ::before , ::after

### 3.defer vs async

默认情况下，在解析html文档时，遇到js脚本后会阻塞解析，知道js脚本download且执行后才继续解析，defer和async分别描述了在解析html时js脚本的下载和执行时机，如下：

![](/images/css/1.png)

脚本下载完，且执行完后才继续解析html（默认）
![](/images/css/2.png)

有async属性时，脚本的下载不会阻塞html解析，但是执行期间会，直到执行完毕才继续解析html
![](/images/css/3.png)

有defer属性时，脚本的下载不阻塞html解析，当解析完毕后再去执行脚本（推荐）
![](/images/css/4.png)


### 4.页面渲染

- 1.首先根据url请求html并且进行解析，参考（3）
  
- 2.根据html和css生成DOM和CSSOM

  生成DOM为`Parse HTML`, 生成CSSOM为`Recalculate style`。

  当正在解析html时，若遇到script标签，则会停止构建DOM，开始下载并且交由js引擎（默认不加defer/async时）去执行，完成后才会恢复DOM构建。

  在执行js脚本时，js是可以修改DOM和CSSOM（比如改样式）的，此时浏览器会阻塞js的执行，直到CSSOM构建完成（外部样式还需要下载）才会恢复js的执行。

//DOM

```
html {
  head,
  body {

  }
}
```

//CSSOM

```
html {
  backgourd: blue;
  body {
    font-size: 16px
  }
  ...
}
```

- 3.生成渲染树(render tree)

  对于`visibility: hidden`和`display: none`来说：后者是不会出现在render tree上的，但是在DOM tree上是有的。

- 4.重排（layout)

  在devtools里为`Layout`

计算各个对象的精确位置，布局，大小等等。

- 5.重绘（paint)

在devtools里为`Paint`

将像素，颜色等填充至屏幕。

因此应当避免一次操作大量DOM或者频繁更改窗口大小，均会导致页面重排。重排也必然会重绘。

- 6.z-index层叠关系

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