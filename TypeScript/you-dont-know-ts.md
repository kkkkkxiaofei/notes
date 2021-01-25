### 1. 基本类型

一眼就能看明白的类型有：`Boolean`, `Number`, `String`, `Array`, `Enum` 

需要特别解释的如下：

`Tuple`: 长度固定且元素可变的数组。

```js
const tuple: [string, number] = ['1', 1];
```

`Unknown`: 未知类型。它是具有类型检查机制的，使用时必须进行类型转换，一般来说，应该用它来代替`any`。

```js
const unknowName: unknown = 1;

console.log(unknowName.title);//compilation error

const anyName: any = 1;

console.log(anyName.title);
```

说明any放弃类型检查，unknown并没有。

```js
let unknownName: unknown;

let unknownTitle: string = unknownName;////compilation error


let anyName: any;

let anyTitle = anyName;
```

any既可以分配给任意类型，也可以被任意类型分配；而unknown只能分配给unknown，但却可以被任意类型分配。

即any为top type + bottom type, unknow只是top type.

`Never`: 从来不会发生的类型。

```js

const loop = () => {
  while(true) 
    console.log(1)
}

const throwError = () => throw new Error('xxx');
```

以上两个函数的返回值其实都是never类型的，这和void是有区别的，比如：

```js
function voidFn(): never {
  Math.ceil(1.1);
}

voidFn();

```
这里预编译就会报错： `A function returning never could not have a reachable end point`;