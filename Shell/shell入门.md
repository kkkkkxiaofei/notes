##### 1.Shell的第一行#!

dev.sh：

```sh
#! /bin/sh
who
```

`#! /bin/sh`表示利用/bin/sh作为当前的Shell，当不写第一行时，系统将默认使用 /bin/sh

##### 2.传递/接收参数

dev.sh：

```sh
#! /bin/sh
echo "${1} ${2} ${3}"
```

调用：

```sh
dev.sh a b c
```

输出：

a b c

`${num}`表示第几个参数，num从1开始，num为0时表示Shell脚本名。

##### 3.常用系统级变量

|变量|含义|
|---|---|
|`$#`|参数个数|
|`$*`,`$@`|全部参数|
|`$?`|命令行返回值（正常0，异常非0)|

##### 4.if条件语句

dev.sh：

```sh
#! /bin/sh
if [[ $1 > 0 ]]; then
  echo "greater than 0"
elif [[ $1 < 0 ]]; then
  echo "less than 0"
else
  echo "equal to 0"
fi
```

`elif`代表elseif，`if`必须要以`fi`进行结尾闭合。其中`[]`也可以用`()`代替，但必须都有两对才能形成条件判断表达式。

##### 5.for循环

dev.sh：

```sh
#! /bin/sh
for (( i = 0;i < 5;i++ )); do
  echo $i
done

for j in 1 2 3 4 5; do
  echo $j
done
```

两种写法都行，适用于不同的情况。

##### 6.while循环

dev.sh：

```sh
#! /bin/sh
i=1
while [ $i -le 3 ]; do
  echo $i
  i=`expr $i + 1`
done
```

输出：

1
2
3

这里得注意：`[ $i -le 3]`等价于`(( $i <= 3 ))`。

##### 7.case语句

dev.sh：

```sh
#! /bin/sh
case $1 in
  "a") echo "this is a";;
  "b") echo "this is b";;
  "c") echo "this is c";;
esac
```

case语句相当于其他编程语言的switch case，它以`esac`作为闭合结尾，每一个case的都需要用`)`包裹，并且command调用结束后又两个`;;`。