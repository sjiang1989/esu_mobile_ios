/*
 * Copyright 2016 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.registration;

import android.content.Context;
import android.database.Cursor;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;

import com.ellucian.mobile.android.adapter.CheckableCursorAdapter;

import java.util.ArrayList;
import java.util.List;


class RegistrationCartCheckableAdapter extends CheckableCursorAdapter {

    private final List<OnCartCheckBoxClickedListener> listenerList = new ArrayList<>();

    RegistrationCartCheckableAdapter(Context context, int layout, Cursor c, String[] from, int[] to, int flags, int checkBoxResId) {
        super(context, layout, c, from, to, flags, checkBoxResId);
    }

    interface OnCartCheckBoxClickedListener {

        void onCartCheckBoxClicked(CheckBox checkBox, boolean isChecked, int position,
                                   String termId, String sectionId);
    }


    void registerOnCartCheckBoxClickedListener(OnCartCheckBoxClickedListener value) {
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

        checkBox.setOnClickListener(new View.OnClickListener(){

        String sectionId = cursor.getString(cursor.getColumnIndex(RegistrationActivity.SECTION_ID));
        String termId = cursor.getString(cursor.getColumnIndex(RegistrationActivity.TERM_ID));

            @Override
            public void onClick(View v) {
                CheckBox checkBox = (CheckBox)v;
                boolean checked = checkBox.isChecked();
                if (checked) {
                    checkedStates.set(position, true);
                } else {
                    checkedStates.set(position, false);
                }
                for (OnCartCheckBoxClickedListener listener : listenerList) {
                    listener.onCartCheckBoxClicked(checkBox, checked, position, termId, sectionId);
                }
            }

        });

        boolean state = checkedStates.get(position);

        checkBox.setChecked(state);
        setCheckBoxAtPosition(position, checkBox);
        bindView(row, context, cursor);
        return row;
    }
}
