import Foundation

extension Dictionary where Key == String {
	func flatten() -> [String: Any] {
		var result = [String: Any]()
		func flattenDic(_ dic: [Key: Value], out: inout [String: Any], addedKey: String = "") {
			for (key, val) in dic {
				let modKey = addedKey.isEmpty ? key : [addedKey, key].joined(separator: ".")
				if let val = val as? [Key: Value] {
					flattenDic(val, out: &out, addedKey: modKey)
				} else {
					// overwrite if key exists, but very rare case
					out[modKey] = val
				}
			}
		}
		flattenDic(self, out: &result)
		return result
	}

	func unflatten() -> [String: Any] {
		let resultDict = NSMutableDictionary()
		for (key, value) in self {
			let parts = key.components(separatedBy: ".")
			var d = resultDict
			for part in parts.dropLast() {
				if d[part] == nil {
					d[part] = NSMutableDictionary()
				}
				d = d[part] as! NSMutableDictionary
			}
			d[parts.last!] = value
		}
		return resultDict as! [String: Any]
	}
}
