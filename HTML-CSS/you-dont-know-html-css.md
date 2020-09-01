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
