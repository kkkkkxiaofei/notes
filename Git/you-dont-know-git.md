### 1.Rebase and Merge

`Rebase`: 会将当前分支上的最新提交放在目标分支的最顶端（无论当前分支是何时创建），这样就使得分支上的提交永远是基于目标分支，且是最新的。

缺点：不“尊重”历史的；若有冲突得一个一个修。原分支已变基，已经被破坏；

优点：分支结构清晰简单。

`Merge`: 会将新提交打包为一个merge提交，并且有基于merge的parent上下文。、

缺点：分支结构复杂

优点：只需要处理一次冲突；会冗余一个merge的提交；原分支保持不变；

总结：

1.不要在公共分支上执行rebase，只能在私有分支。

2.分支开发最佳合并分支：

```
git pull -r origin master
git co feature
git pull -r origin feature
git rebase master
git co master
git merge feature
```

