<?php
/*
 * Created on Feb 8, 2010
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
 class ServiceFilterManager {
 	
 	private static $myFilterList = null;
 	
 	private function ServiceFilterManager() {
 		$this->myFilterList = array();
 	}
 	
 	public function setFilter($key, $value) {
 		$this->myFilterList[$key] = $value;
 	} 
 	
 	public function getFilter($key) {
 		return $this->myFilterList[$key];
 	}
 	
 	public function getFilterList() {
 		return $this->myFilterList;
 	}
 	
 	function &getInstance ()
    // this implements the 'singleton' design pattern.
    {
        static $instance;
 
        if (!isset($instance)) {
            $c = __CLASS__;
            $instance = new $c;
        } // if
 
        return $instance;
 
    } // getInstance
 	
 	
 	
 	
 }
?>
