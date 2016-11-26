//
//  ViewController.swift
//  libPhoneNumber-SwiftDemo
//
//  Created by tabby on 2015. 11. 8..
//  Copyright © 2015년 ohtalk.me. All rights reserved.
//

import UIKit
import libPhoneNumberiOS


class ViewController: UIViewController {
    let textField: UITextField = NBTextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        textField.backgroundColor = UIColor.white
        textField.frame.size.width = 200
        textField.frame.size.height = 25
        
        view.addSubview(textField)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textField.center = self.view.center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

