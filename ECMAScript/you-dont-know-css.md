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

有async属性时，脚本的下载不会阻塞html解析，但是执行期间会，知道执行完毕才继续解析html
![](/images/css/3.png)

有defer属性时，脚本的下载不阻塞html解析，当解析完毕后再去执行脚本（推荐）
![](/images/css/4.png)


### 4.页面渲染

- 1.首先根据url请求html并且进行解析，参考（3）

- 2.根据html和css生成DOM和CSSOM

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

- 3.生成渲染树

- 4.重排（layout)

计算各个对象的精确位置，布局，大小等等。

- 5.重绘（paint)

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

默认层叠顺序为由上到下，由外到内，子节点永远不能高于父节点层级。