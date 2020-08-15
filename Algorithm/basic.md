### 链表

### 树

- 初始化二叉树

```
var arr = [20, 12, 27, 9, 19, 30, 22, 7, 10, 40];

function Node(value) {
	this.value = value;
	this.left = null;
	this.right = null;
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
	
	for(var i =1;i < arr.length;i++) {
		insert(root, arr[i]);
	}
	return root;
}
init(arr)

```
