/*
 * Copyright 2016 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.registration;

import android.content.Context;
import android.database.Cursor;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Adapter;
import android.widget.CheckBox;

import com.ellucian.elluciango.R;
import com.ellucian.mobile.android.adapter.CheckableCursorAdapter;
import com.ellucian.mobile.android.adapter.CheckableSectionedListAdapter;

import static com.ellucian.mobile.android.registration.RegistrationActivity.SECTION_ID;
import static com.ellucian.mobile.android.registration.RegistrationActivity.TERM_ID;


class RegistrationCartListAdapter extends CheckableSectionedListAdapter {
    private static final String TAG = RegistrationCartListAdapter.class.getSimpleName();

    private LayoutInflater mInflater;
    private String alternateIdentifier;
    private int alternateHeaderResId;

    // Constructor used by Cart tab allows for 2 types of section headers
    RegistrationCartListAdapter(Context context, int alternateHeaderResId, String alternateIdentifier) {
        super(context, R.layout.list_header, R.id.list_header_title);
        this.alternateIdentifier = alternateIdentifier;
        this.alternateHeaderResId = alternateHeaderResId;
        mInflater = (LayoutInflater)context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        int positionsAlreadyChecked = 0;

        // Loop through each group of terms. See how many items are in each group so we
        // can determine if this position is part of this group.
        for(int termSection = 0; termSection < this.headers.getCount(); termSection++) {
            Adapter termSectionAdapter = sections.get(termSection);
            int termSectionSize = termSectionAdapter.getCount()+1;

            if (position+1 <= termSectionSize + positionsAlreadyChecked) {
                // The item we're building the view for IS in this group.
                // Determine if it's a header view
                int positionInGroup = position - positionsAlreadyChecked;
                String identifier = identifiers.get(termSection);

                if (positionInGroup == 0) {
                    // Log.v(TAG, "It's a header in group:" + termSection + ". Position:"+position + "  positionsAlreadyChecked:" + positionsAlreadyChecked);
                    if (identifier != null && alternateIdentifier != null
                            && identifier.contains(alternateIdentifier)) {
                        convertView = mInflater.inflate(alternateHeaderResId, null);
                        return headers.getView(termSection, convertView, parent);
                    } else {
                        convertView = mInflater.inflate(R.layout.list_header, null);
                        return headers.getView(termSection, convertView, parent);
                    }
                } else {
                    //  Log.v(TAG, "It's a NON-header in group:" + termSection + ". Position:"+position + "  positionsAlreadyChecked:" + positionsAlreadyChecked);
                    return termSectionAdapter.getView(positionInGroup-1, convertView, parent);
                }

            } else {
                // Position is not part of this group. Increment counter and continue looping.
                //  Log.v(TAG, "Position: "+ position +" isn't in group: " + termSection + ". Moving on...");
                positionsAlreadyChecked += termSectionSize;
                continue;
            }

        }
        return null;
    }

    void uncheckCheckbox(int position, String termId, String sectionId) {
        for(int i = 0; i < this.headers.getCount(); i++) {
            CheckableCursorAdapter section = (CheckableCursorAdapter) sections.get(i);

            Cursor cursor = (Cursor) section.getItem(position);
            String cursorSectionId = cursor.getString(cursor.getColumnIndex(SECTION_ID));
            String cursorTermId = cursor.getString(cursor.getColumnIndex(TERM_ID));

            if (TextUtils.equals(termId,cursorTermId)
                    && TextUtils.equals(sectionId,cursorSectionId)) {
                CheckBox checkbox = section.getCheckBoxAtPosition(position);
                if (checkbox !=null) {
                    if (checkbox.isChecked()) {
                        checkbox.setChecked(false);
                    }
                }
                return;
            }
        }
    }

    // Returns the high-level RegCartAdapter position
    @SuppressWarnings("unused")
    public int getPositionByTermAndSection(int position, String termId, String sectionId) {
        int cartPosition = 0;

        for(int i = 0; i < this.headers.getCount(); i++) {
            CheckableCursorAdapter section = (CheckableCursorAdapter) sections.get(i);
            int sectionCount = section.getCount();

            Cursor cursor = (Cursor) section.getItem(position);
            String cursorSectionId = cursor.getString(cursor.getColumnIndex(SECTION_ID));
            String cursorTermId = cursor.getString(cursor.getColumnIndex(TERM_ID));

            if (TextUtils.equals(termId,cursorTermId)
                && TextUtils.equals(sectionId,cursorSectionId)) {
                return cartPosition+1;
            } else {
                cartPosition = cartPosition+sectionCount+1;
            }

        }

        return cartPosition;
    }

}
