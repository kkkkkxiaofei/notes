### 1. 基本类型

一眼就能看明白的类型有：`Boolean`, `Number`, `String`, `Array`, `Enum`

需要特别解释的如下：

`Tuple`: 长度固定且元素可变的数组。

```js
const tuple: [string, number] = ["1", 1];
```

`Unknown`: 未知类型。它是具有类型检查机制的，使用时必须进行类型转换，一般来说，应该用它来代替`any`。

```js
const unknowName: unknown = 1;

console.log(unknowName.title); //compilation error

const anyName: any = 1;

console.log(anyName.title);
```

说明 any 放弃类型检查，unknown 并没有。

```js
let unknownName: unknown;

let unknownTitle: string = unknownName; ////compilation error

let anyName: any;

let anyTitle = anyName;
```

any 既可以分配给任意类型，也可以被任意类型分配；而 unknown 只能分配给 unknown，但却可以被任意类型分配。

即 any 为 top type + bottom type, unknow 只是 top type.

`Never`: 从来不会发生的类型。

```js
const loop = () => {
  while (true) console.log(1);
};

const throwError = () => throw new Error("xxx");
```

以上两个函数的返回值其实都是 never 类型的，这和 void 是有区别的，比如：

```js
function voidFn(): never {
  Math.ceil(1.1);
}

voidFn();
```

这里预编译就会报错： `A function returning never could not have a reachable end point`;

### 2. d.ts 的最佳管理方式

[参考](https://medium.com/jspoint/typescript-type-declaration-files-4b29077c43)

### 3. typescript 的模块加载

[参考](https://medium.com/jspoint/typescript-module-system-5022cac310f6)

### 4. typescript 的编译

`module`: 表明需要用怎样的模块机制来做处理，比如设置为`ES5`，那么当遇到`Import`时，就会解析为`require/export`;若设置为`ES6`，则`Import`则不会变。通常`module`若不显式设置，其的默认值是由`target`来控制。

`outFile`: 在设置`module`为`None | System | AMD`时，可以对输出进行打包。注意此配置不能用来代替打包工具，因为它无法打包`ES module`或者`Commonjs module`。

`lib`: ts 中内建的声明文件都在这（如`Dom`, `Promise`, `Window`..)，默认情况下`target`会决定`lib`的选项。比如`Target`为`ES5`, 那`lib`就对应为`'DOM', 'ES5', 'ScriptHost'`。因为`target`会控制`lib`，所以如果不想让编译器用默认的`lib`，可以设置`noLib`为`true`。

`typeRoots`: `lib`里的声明文件可以让`IDE`捕捉到代码提示，但是毕竟它是由`target`决定的;`typeRoot`就可以允许我们自己定义声明文件的位置。

`baseUrl`: 非相对路径的起点路径，默认是`.`，找不到则会去`node_modules`里寻找。

`paths`: 类似于自定义路径别名，可定义多个。

`rootDirs`: 与`baseUrl`相反，`rootDirs`可以规定使用相对路径的模块应该去哪里寻找。

[参考][https://medium.com/jspoint/typescript-compilation-the-typescript-compiler-4cb15f7244bc]
