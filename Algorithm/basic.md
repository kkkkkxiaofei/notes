### 队列与栈

- 循环队列

循环队列需要头尾指针，入队时，尾指针向后移动；出队时，头指针向后移动。

头指针溢出的处理：

```
front = (front + 1) % capacity //capacity为队列最大长度
```

利用头指针可以计算出尾指针的位置（考虑溢出）：

```
rear = (front + count - 1) % capacity //count为队列长度
```

循环队列的基本实现：

```
class Queue() {
  constructor(capacity) {
    this.capacity = capacity;
    this.buffer = new Array(capacity)
    this.front = 0;
    this.count = 0;
  }

  enQueue(item) {
    if (!this.isFull()) {
      this.count++;
      this.buffer[(this.front + this.count - 1) % this.capacity] = item;
      return true;
    }
    return false;
  }

  deQueue(item) {
    if (!this.isEmpty()) {
      this.count--;
      this.front = (this.front + 1) % this.capacity;
      return true;
    }
    return false;
  }

  isEmpty() {
    return this.count === 0;
  }

  isFull() {
    return this.count === this.capacity;
  }
}

```

### 链表

### 树

- 初始化二叉树

```
var arr = [20, 12, 27, 9, 19, 30, 22, 7, 10, 40, 29];

function Node(value) {
  this.value = value;
  this.left = null;
  this.right = null;
  this.isLeaf = this.left || this.right;
}

function insert(root, value) {
  if (value < root.value) {
    if (root.left) {
      insert(root.left, value);
    } else {
      root.left = new Node(value);
    }
  } else {
    if (root.right) {
      insert(root.right, value);
    } else {
      root.right = new Node(value);
    }
  }
}

function init(arr) {
  var root = new Node(arr[0]);

  for (var i = 1; i < arr.length; i++) {
    insert(root, arr[i]);
  }
  return root;
}
var root = init(arr);
```
初始化后的二叉树：

         20
       /    \
      12    27
     /   \  /  \
    9    19 22  30
  /  \         /  \ 
 7   10      29    40

 - 计算深度

 ```
 function calcDepth(root) {
   if (root) {
     const leftDepth = calcDepth(root.left);
     const rightDepth = calcDepth(root.right);
     return Math.max(leftDepth, rightDepth) + 1;
   }
   return 0;
 }
 ```

 - DFS

 ```
function dfs(root) {
  const stack = [root];
  while (stack.length > 0) {
    const node = stack.pop();
    console.log(node.value);
    if (node.right) {
      stack.push(node.right);
    }
    if (node.left) {
      stack.push(node.left);
    }
  }
}  
 ```
 输出：[20,12,9,7,10,19,27,22,30,29,40]

 - BFS 

 ```
 function bfs(root) {
  const queue = [root];
  while (queue.length > 0) {
    const node = queue.shift();
    console.log(node.value);
    if (node.left) {
      queue.push(node.left);
    }
    if (node.right) {
      queue.push(node.right);
    }
  }
}
 ```
输出：[20,12,27,9,19,22,30,7,10,29,40]