import UIKit

//https://keisan.casio.jp/exec/system/1161228774
//atanはアークタンジェント
// sqrtは平方根(√)
// https://manapedia.jp/text/648
//垂直に交わるということは、２つの直線の傾きの積が－１になればいいということでしたね。

// https://www.s-yamaga.jp/nanimono/sonota/kodoho.htm
// 180 = πrad

let a: Double = 2.0
let b: Double = 1.0

let θ = atan(b/a)

let c = sqrt(pow(a, 2) + pow(b, 2))
let c2 = c * 2

let a2 = c2 * cos(θ)
let b2 = sqrt(pow(c2, 2) - pow(a2, 2))

//let p = CGPoint(x: 10, y: 10)
//let a = p.y / p.x
//let a2 = -(1 / a)

