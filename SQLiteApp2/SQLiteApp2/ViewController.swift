//
//  ViewController.swift
//  SQLiteApp2
//
//  Created by class24 on 2016/9/1.
//  Copyright © 2016年 GUO. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var chineseTextField: UITextField!
    @IBOutlet weak var mathTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var insertButton: UIButton!
    // 儲存學生資料陣列
    var studentsArray: Array<Dictionary<String,String>> = []
    // 資料庫設定參數
    var db: COpaquePointer = nil
    var records: COpaquePointer = nil
    var currentNumber: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.addButton.enabled = true
        self.insertButton.enabled = false
        
        let fileManager: NSFileManager = NSFileManager()
        // 釋放記憶體
        db = nil
        // 取得專案中的資料庫
        let srcPath = NSBundle.mainBundle().pathForResource("StudentDB", ofType: "sqlite")
        // 取得手機的Documents位置
        let destPath = NSHomeDirectory() + "/Documents/StudentDB.sqlite"
        // 拷貝資料庫：不存在此檔案才拷貝
        if !fileManager.fileExistsAtPath(destPath) {
            do { try fileManager.copyItemAtPath(srcPath!, toPath: destPath) } catch _ { print("error") }
        }
        // 開啟資料庫
        if sqlite3_open(destPath, &db) != SQLITE_OK {
            showAlert("開啟資料庫失敗", message: "請檢查資料庫是否存在")
            exit(1)
        }
        // 清空記憶體
        records = nil
        // 讀取資料庫
        // SQL 語法
        let sql: NSString = "Select * From class101"
        if sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &self.records, nil) != SQLITE_OK {
            self.showAlert("讀取資料庫資料失敗", message: "請確認您的資料庫內容")
            exit(1)
        } 
        
        // 撈取資料庫資料
        while sqlite3_step(records) == SQLITE_ROW {
            let id = sqlite3_column_int(records, 0)
            let strName = sqlite3_column_text(records, 1)
            let name = String.fromCString(UnsafePointer<CChar>(strName))
            let chinese = sqlite3_column_int(records, 2)
            let math = sqlite3_column_int(records, 3)
            let dict: Dictionary<String, String> = ["id": String(id), "name": name!, "chinese": String(chinese), "math": String(math)]
            self.studentsArray.append(dict)
        }
        // 關閉資料庫
        sqlite3_finalize(records)
        // 重整表格
        self.tableView.reloadData()
        // 預設顯示第一筆資料
        self.showSingle(self.currentNumber)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // 顯示訊息窗
    func showAlert(title: String, message: String) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "確定", style: .Default, handler: { (action1) in
            
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    // 顯示訊息窗
    func showUpdateAlert(title: String, message: String) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .Default, handler: { (action1) in
            
        }))
        alertController.addAction(UIAlertAction(title: "確定", style: .Default, handler: { (action2) in
            // SQL 語法：更新資料
            let sql: NSString = "Update class101 Set s_name='\(self.nameTextField.text!)',s_chinese=\(self.chineseTextField.text!),s_math=\(self.mathTextField.text!) Where s_id=\(self.numberLabel.text!)"
            // 清空資料暫存區域
            self.records = nil
            // 讀取資料庫
            if sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &self.records, nil) != SQLITE_OK {
                self.showAlert("讀取資料庫資料失敗", message: "請確認您的資料庫內容")
                exit(1)
            } 
            // 判斷是否更新成功
            if sqlite3_step(self.records) == SQLITE_DONE {
                self.showAlert("成功", message: "更新資料成功！")
                // 更新陣列資料
                (self.studentsArray[self.currentNumber])["name"] = self.nameTextField.text!
                (self.studentsArray[self.currentNumber])["chinese"] = self.chineseTextField.text!
                (self.studentsArray[self.currentNumber])["math"] = self.mathTextField.text!
                // 更新表格
                self.tableView.reloadData()
            } else {
                self.showAlert("失敗", message: "更新資料失敗！")
            }
            
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    // 顯示訊息窗
    func showDeleteAlert(title: String, message: String) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .Default, handler: { (action1) in
            
        }))
        alertController.addAction(UIAlertAction(title: "確定", style: .Default, handler: { (action2) in
            // SQL 語法：刪除資料
            let sql: NSString = "Delete From class101 Where s_id=\(self.numberLabel.text!)"
            
            self.records = nil
            // 讀取資料庫
            if sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &self.records, nil) != SQLITE_OK {
                self.showAlert("讀取資料庫資料失敗", message: "請確認您的資料庫內容")
                exit(1)
            }
            // 讀取資料是否成功
            if sqlite3_step(self.records) == SQLITE_DONE {
                self.showAlert("成功", message: "刪除資料成功！")
                // 刪除陣列資料
                self.studentsArray.removeAtIndex(self.currentNumber)
                // 更新 self.currentNumber
                if self.currentNumber == self.studentsArray.count {
                    self.currentNumber = self.studentsArray.count - 1
                } 
                // 重新整理表單
                self.tableView.reloadData()
            }
            
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // 顯示選擇的資料筆資料
    func showSingle(index: Int) {
        self.numberLabel.text = self.studentsArray[index]["id"]!
        self.nameTextField.text = self.studentsArray[index]["name"]!
        self.chineseTextField.text = self.studentsArray[index]["chinese"]!
        self.mathTextField.text = self.studentsArray[index]["math"]!
    }
    // 刪除
    @IBAction func deleteAction(sender: UIButton) {
        if self.studentsArray.count > 1 {
            self.showDeleteAlert("刪除", message: "確定要刪除此筆資料？")
        } else {
            self.showAlert("錯誤", message: "至少建立一筆資料才能做刪除！")
        }
    }
    // 修改
    @IBAction func updateAction(sender: UIButton) {
        self.showUpdateAlert("更新", message: "確定要更新此筆資料？")
    }
    // 清除
    @IBAction func cleanAction(sender: UIButton) {
        // 出除欄位內容文字
        self.numberLabel.text = ""
        self.nameTextField.text = ""
        self.chineseTextField.text = ""
        self.mathTextField.text = ""
        // 變更按鈕使用權限
        self.addButton.enabled = false
        self.insertButton.enabled = true
    }
    // 寫入
    @IBAction func insertAction(sender: UIButton) {
        // 變更按鈕使用權限
        self.addButton.enabled = true
        self.insertButton.enabled = false
        // SQL語法：
        let sql: NSString = "Insert into class101 (s_name,s_chinese,s_math) Values ('\(self.nameTextField.text!)',\(self.chineseTextField.text!),\(self.mathTextField.text!))"
        // 清空資料暫存區域
        self.records = nil
        // 讀取資料庫
        sqlite3_prepare_v2(db, sql.UTF8String, -1, &records, nil)
        // 讀取資料有無成功
        if sqlite3_step(records) == SQLITE_DONE {
            self.showAlert("新增資料成功", message: "")
        } else {
            self.showAlert("新增資料失敗", message: "")
        }
        // 取得欄位資料
        let id = String(sqlite3_last_insert_rowid(db))
        let name = self.nameTextField.text!
        let chinese = self.chineseTextField.text!
        let math = self.mathTextField.text!
        // 將欄位資料建立Dictionary、並加入陣列中
        let dict: Dictionary<String, String> = ["id": id, "name": name, "chinese": chinese, "math": math]
        self.studentsArray.append(dict)
        // 重新整理表單
        self.tableView.reloadData()
        self.showSingle(self.studentsArray.count - 1)
        
    }
    
    // 表格設定
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.studentsArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = self.studentsArray[indexPath.row]["name"]!
        cell.detailTextLabel?.text = "編號：\(self.studentsArray[indexPath.row]["id"]!), 國文：\(self.studentsArray[indexPath.row]["chinese"]!), 數學：\(self.studentsArray[indexPath.row]["math"]!)"
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 變更按鈕使用權限
        self.addButton.enabled = true
        self.insertButton.enabled = false
        
        self.currentNumber = indexPath.row
        // 顯示點選項目資料
        self.showSingle(self.currentNumber)
    }

}

