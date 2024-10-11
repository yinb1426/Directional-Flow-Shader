# 动态流动水体Shader
## 概述
动态流动水体Shader基于FlowMap，将水体以**动态流动**方式呈现，并根据流动方向添加**泡沫**以加强流动呈现效果，用以呈现大范围水体流动效果。
## 特性
* 基于用户提供的FlowMap以及水深纹理WaterHeightTexture，实现流动效果。
* 使用Blinn-Phong模型中的半兰伯特漫反射部分，实现光照效果。考虑到应用场景，没有加入高光部分
* 设置4种波浪参数，实现无缝流动效果
* 根据水深阈值混合泡沫纹理，以加强流动效果
## Shader情况说明
本工程提供2份Shader文件：Directional Flow Dynamic Shader、Directional Flow Shader。
二者的差异在于：
* 前者需要两份前后FlowMap和水深纹理，且需要提供插值参数以获取Lerp后的水流速度和水深值。
* 后者仅需要一份FlowMap和水深纹理
二者的使用场景如下：
* 当有多个时间节点的FlowMap和水深纹理，需要连续显示水流运动过程时，请使用Directional Flow Dynamic Shader
* 当仅有一个时间节点的FlowMap和水深纹理，需要观察某一时刻的水流运动时，请使用Directional Flow Shader
> 之后的参数说明将以Directional Flow Shader为例
## 参数
**常规及贴图**：
| 参数 | 类型 | <center>说明</center> | 建议参考值 |
| :------: | :------: | ------ | :------: |
| DisplacementMap | 2D | 平面波浪高度的位移贴图 | |
| NormalMap | 2D | 平面波浪高度位移贴图对应的法线贴图 | |
| NormalStrength | Float | 法线强度 | 0.7 |
| FlowMap | 2D | 流向贴图 | |
| WaterHeightTexture | 2D | 水深贴图 (也可以使用CG方法获取水深) | |

**水体颜色与水深**：
| 参数 | 类型 | <center>说明</center> | 建议参考值 |
| :------: | :------: | ------ | :------: |
| WaterShallowColor | Color | 浅水颜色 | (4, 93, 111, 170) |
| WaterDeepColor | Color | 深水颜色 |  (78, 110, 133, 240) |
| DepthDensity | Float | 调节水深的系数，用于更好地显示水体颜色 | 1 |

**波浪参数**：
| 参数 | 类型 | <center>说明</center> |
| :------: | :------: | ------ |
| GridResolution | Float | 水面细分网格大小 |
| WavePeriod | Float | 控制位移贴图(三角函数)的周期 |
| FlowVelocityStrength | Float | 流速控制 |
| HeightEdge | Float | 水深阈值，用于拉伸水高 |
* 波浪参数共4组，建议参考值为：
    * (40, 1.578, 5, 0.232)
    * (60, 1.36, 3.5, 0.227)
    * (70, 1.6, 2.2, 0.243)
    * (50, 2.54, 4.2, 0.265)

**浪尖泡沫**：
| 参数 | 类型 | <center>说明</center> | 建议参考值 |
| :------: | :------: | ------ | :------: |
| FoamTexture | 2D | 泡沫纹理 | Tiling = 300X300 | 
| FoamMinEdge | Range(0, 1) | 显示泡沫的最低高度 | 0.3 |
| FoamMaxEdge | Range(0, 1) | 显示泡沫的最高高度 | 0.5 |
| FoamBlend | Range(0, 1) | 和水体颜色的混合程度 | 0.7 |
## 参考
* https://www.youtube.com/watch?v=XCvaH7nRDmg
* https://onlinelibrary.wiley.com/doi/full/10.1111/cgf.13669
* https://catlikecoding.com/unity/tutorials/flow/directional-flow/
