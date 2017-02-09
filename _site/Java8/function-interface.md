##### 需求

C团队是一个敏捷开发团队，它们的产品每天都会进行几十次的小版本发布，如此频繁的持续集成必须有良好的代码作为保证。为此，PM在CI中的构建任务中设定了“门槛”，所有部署必须进行`Sonar`代码扫描，满足一定的阀值才可以进行正常发布，以此保证产品质量。具体指标如下：

1.工程的测试覆盖率必须大于90%

##### 分析

获取所有工程，筛选出测试覆盖率大于90%的工程，进行发布，so easy~

##### 实现

```
    private static List<Project> getValidProjects(List<Project> projectList) {
        List<Project> validProjects = new ArrayList<>();
        for(Project project : projectList) {
            if(project.getTestCoverage() > 0.9) {
                validProjects.add(project);
            }
        }
        return validProjects;
    }

```

代码很简单，这是java8之前的实现。当然了，我很还可以将`project.getTestCoverage() > 0.9`抽象成`project.isValid()`，这下看起来似乎没太大问题了。

需求2来了，PM的规定的新指标如下：

1.工程的测试覆盖率必须大于90%
2.code smell数不能超过3个

你很快速的在`Project.java`里抽象出了：

```
public boolean isValid() {
    return this.getTestCoverage() > 0.9 && this.getCodeSmellNum() < 3;
}
```

部署时还时老出现问题，PM再次提高质量门槛，指标如下：

1.工程的测试覆盖率必须大于90%
2.code smell数不能超过3个
3.扫描问题数不超过3个
4.API测试用例数大于10
5.UI测试用例数大于10
...
...
...

此时你的是不想把PM弄死，可你还是在此基础上添加了N多判断。

Java8来啦。。。。

##### Predicate

仔细分析现在的需求，其实想要实现的方法是“某种行为”的结果来导向校验的集合，也就说上面的方法参数应该类似：

```
    private static List<Project> getValidProjects(List<Project> projectList, Validation validation) {
        List<Project> validProjects = new ArrayList<>();
        for(Project project : projectList) {
            if(validation.test()) {
                validProjects.add(project);
            }
        }
        return validProjects;
    }

```

将所有的情况都统一抽象成Validation接口，接口中的`test`方法表示校验结果。如果这样做，就变成了多态，当然可以实现，不过就得设计的比较复杂，好好的一个筛选，硬要写个接口在写N多类去实现，岂不是很槽糕。Java8在此基础上帮我们实现了函数接口，可以将`validation`看作是一个还未被执行的方法，对应的，我们可以这么写：

```
  private static List<Project> getValidProjects(List<Project> projectList, Predicate<Project> p) {
        List<Project> validProjects = new ArrayList<>();

        for(Project project : projectList) {
            if(p.test(project)) {
                validProjects.add(project);
            }
        }
        return validProjects;
    }
```

```
  List<Project> validProjects = getValidProjects(projectList, project-> project.getTestCoverage() > 0.9);
```


将`project-> project.getTestCoverage() > 0.9`作为方法参数传递看起来很酷吧，对应的，我们可以聚合上面的多种`predicate`:

```
    Predicate<Project> testCoveragePredicate = project-> project.getTestCoverage() > 0.9;
    Predicate<Project> codeSmellPredicate = project-> project.getCodeSmellNum() < 3;
    Predicate<Project> issuePredicate = project-> project.getIssueCount() < 3;
    Predicate<Project> apiPredicate = project-> project.getApiCount() > 10;
    Predicate<Project> uiPredicate = project-> project.getApiCount() > 10;

    Predicate<Project> projectPredicate = testCoveragePredicate
            .and(codeSmellPredicate)
            .and(codeSmellPredicate)
            .and(issuePredicate)
            .and(apiPredicate)
            .and(uiPredicate);

    List<Project> validProjects = getValidProjects(projectList, projectPredicate);
```

这样的代码，既然漂亮，又表意，而且可维护性还更高，很酷吧。不过不难看出，`Predicate`是`T->boolean`的形式，如果需要其他类型怎么办呢？这里简单介绍其他两个函数接口

##### Consumer and Function

`Consumer`, `Function`与`Predicate` 类似只不过前者是`T->void`的形式，而后者是`T->R`的形式，并且实现的方法略有不同。

Demo for Consumer: 

```
  private static void displyAllCodeSmell(List<Project> projectList, Consumer<Project> c) {
       for(Project project : projectList) {
           c.accept(project);
       }
  }
```

```
  displyAllCodeSmell(projectList, project -> System.out.println(project.getCodeSmellNum()));

```

Demo for Function:

```
  private static int calcAllIssueCount(List<Project> projectList, Function<Project, Integer> f) {
        int sum = 0;
        for(Project project : projectList) {
            sum += f.apply(project);
        }
        return sum;
  }
```

```
  calcAllIssueCount(projectList, project -> project.getIssueCount());
```

##### 其他函数接口

本文只能旨在介绍函数接口的思想和用法，并不能一一介绍，具体列表参考如下：

| Function Interface | Description    |
|--------------------|----------------|
| Predicate<T>       | T->boolean     |
| Consumer<T>        | T->void        |
| Function<T>        | T->R           |
| Supplier<T>        | ()->T          |
| UnaryOperator<T>   | T->T           |
| BinaryOperator<T>  | (T,T)->T       |
| BiPredicate<L,R>   | (L,R)->boolean |
| BiConsumer<T,U>    | (T,U)->void    |
| BiFunction(T,U,R)  | (T,U)->R       |