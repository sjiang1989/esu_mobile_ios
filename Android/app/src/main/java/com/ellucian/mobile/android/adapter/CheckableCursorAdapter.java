/*
 * Copyright 2015-2016 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.adapter;

import android.content.Context;
import android.database.Cursor;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.SimpleCursorAdapter;

import java.util.ArrayList;
import java.util.List;

public class CheckableCursorAdapter extends SimpleCursorAdapter {
	public List<Boolean> checkedStates = new ArrayList<>();
	public final List<CheckBox> checkBoxes = new ArrayList<>();
	
	private final List<OnCheckBoxClickedListener> listenerList = new ArrayList<>();
	
	public final Context context;
    public final int layout;
	public final Cursor cursor;
	private final String[] from;
	private final int[] to;
	private final int flags;
	protected final int checkBoxResId;

	public CheckableCursorAdapter(Context context, int layout,
			Cursor c, String[] from, int[] to, int flags, int checkBoxResId) {
		super(context, layout, c, from, to, flags);
		this.context = context;
		this.layout = layout;
		this.cursor = c;
		this.from = from;
		this.to = to;
		this.flags = flags;
		this.checkBoxResId = checkBoxResId;
		for (int i = 0; i < c.getCount(); i++) {
			checkedStates.add(false);
			checkBoxes.add(null);
		}
	}
	
	public interface OnCheckBoxClickedListener {
		
		void onCheckBoxClicked(CheckBox checkBox, boolean isChecked, int position);
	}
	
	public void registerOnCheckBoxClickedListener(OnCheckBoxClickedListener value) {
		listenerList.add(value);
	}
	
	
	@Override
	public View getView(final int position, View convertView, ViewGroup parent) {
		if (!cursor.moveToPosition(position)) {
			throw new IllegalStateException("couldn't move cursor to position " + position);
		}

		LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		final View row = inflater.inflate(layout, null);

		CheckBox checkBox = (CheckBox) row.findViewById(checkBoxResId);

		checkBox.setOnClickListener(new OnClickListener(){ 

			@Override
			public void onClick(View v) {
				CheckBox checkBox = (CheckBox)v;
				boolean checked = checkBox.isChecked();
				if (checked) {
					checkedStates.set(position, true);
				} else {
					checkedStates.set(position, false);
				}
				for (OnCheckBoxClickedListener listener : listenerList) {
					listener.onCheckBoxClicked(checkBox, checked, position);
				}
			}

		});
					
		boolean state = checkedStates.get(position);

		checkBox.setChecked(state);
		setCheckBoxAtPosition(position, checkBox);
		bindView(row, context, cursor);
		return row;
	}

    @SuppressWarnings("unused")
	public List<Integer> getCheckedPositions() {
		List<Integer> checkedPositions = new ArrayList<>();
		for (int i = 0; i < checkedStates.size(); i++) {
			if (checkedStates.get(i)) {
				checkedPositions.add(i);
			}
		} 
		return checkedPositions;
	}
	
	public boolean[] getCheckedStatesAsBooleanArray() {
		boolean[] booleanArray = new boolean[checkedStates.size()];
		for (int i = 0; i < checkedStates.size(); i++) {
			booleanArray[i] = checkedStates.get(i);
		}
		return booleanArray;
	}

    @SuppressWarnings("unused")
	public void setCheckedStates(List<Boolean> value) {
		checkedStates = value;
	}
	
	public void setCheckedStates(boolean[] value) {
		checkedStates = new ArrayList<>();
		for (boolean state : value) {
			checkedStates.add(state);
		}
	}

    @SuppressWarnings("unused")
	public boolean isPositionChecked(int position) {
		return checkedStates.get(position);
	}

    @SuppressWarnings("unused")
	public void setCheckedPositionState(int position, boolean value) {
		checkedStates.set(position, value);
	}

	void resetCheckedStates() {
		for (int i = 0; i < checkedStates.size(); i++) {
			checkedStates.set(i, false);
		}
	}

	protected void setCheckBoxAtPosition(int position, CheckBox checkBox) {
		checkBoxes.set(position, checkBox);
	}
	
	public CheckBox getCheckBoxAtPosition(int position) {
		return checkBoxes.get(position);
	}
}
