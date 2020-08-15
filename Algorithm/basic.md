### 链表

### 树

- 初始化二叉树

```
var arr = [20, 12, 27, 9, 19, 30, 22, 7, 10, 40];

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
  /  \            \ 
 7   10            40

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
