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