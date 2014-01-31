package com.ellucian.mobile.android.util;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import android.text.TextUtils;

public class ModuleConfiguration {
	
	public String configType;
	public String packageName;
	public String activityName;
	public HashMap<String, String> intentExtras;
	public List<Integer> intentFlags;
	
	public ModuleConfiguration() {
		intentExtras = new HashMap<String, String>();
		intentFlags = new ArrayList<Integer>();
	}
	
	public boolean isValid() {
		if (TextUtils.isEmpty(configType) || TextUtils.isEmpty(packageName) || TextUtils.isEmpty(activityName)) {
			return false;
		}
		return true;
	}

}
