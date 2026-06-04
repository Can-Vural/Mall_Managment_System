import streamlit as st
import mysql.connector
from mysql.connector import Error
import pandas as pd


def get_connection():
    try:
        connection = mysql.connector.connect(
            host=st.secrets["mysql"]["host"],
            user=st.secrets["mysql"]["user"],
            password=st.secrets["mysql"]["password"],
            database=st.secrets["mysql"]["database"]
        )
        return connection
    except Error as e:
        st.sidebar.error(f"Connection Error: {e}")
        return None


st.set_page_config(page_title="Mall Management System", layout="wide")


st.sidebar.title("Navigation")
menu = ["System Setup", "Employee Management", "Reports"]
choice = st.sidebar.selectbox("Select Menu", menu)

if choice == "System Setup":
    st.title("System Setup & Definitions")

    conn = get_connection()
    if conn:
        cursor = conn.cursor(dictionary=True)

        col1, col2, col3 = st.columns(3)

        with col1:
            st.subheader("Add Department")
            with st.form("add_dept_form", clear_on_submit=True):
                dept_name = st.text_input("Department Name")
                if st.form_submit_button("Save Department"):
                    try:
                        cursor.execute("INSERT INTO departments (department_name) VALUES (%s)", (dept_name,))
                        conn.commit()
                        st.success("Department added!")
                    except Error as e:
                        st.error(f"Error: {e.msg}")

        with col2:
            st.subheader("Add Brand")
            with st.form("add_brand_form", clear_on_submit=True):
                b_cat_id = st.number_input("Category ID", min_value=1, step=1)
                b_name = st.text_input("Brand Name")
                if st.form_submit_button("Save Brand"):
                    try:
                        cursor.execute("INSERT INTO brands (brand_category_id, brand_name) VALUES (%s, %s)",
                                       (b_cat_id, b_name))
                        conn.commit()
                        st.success("Brand added!")
                    except Error as e:
                        st.error(f"Error: {e.msg}")

        with col3:
            st.subheader("Add Store")

            cursor.execute("SELECT brand_id, brand_name FROM brands")
            brands_data = cursor.fetchall()
            brand_options = {b['brand_name']: b['brand_id'] for b in brands_data}

            with st.form("add_store_form", clear_on_submit=True):
                s_mall_id = st.number_input("Mall ID", min_value=1, step=1)
                s_name = st.text_input("Store Name")

                if brand_options:
                    selected_brand_label = st.selectbox("Select Brand", list(brand_options.keys()))
                    s_brand_id = brand_options[selected_brand_label]
                else:
                    st.warning("Please add a brand first!")
                    s_brand_id = None

                s_sqm = st.number_input("Square Meters", min_value=1, step=10)
                s_floor = st.number_input("Floor", step=1)
                s_is_open = st.checkbox("Is Currently Open?", value=True)

                if st.form_submit_button("Save Store"):
                    if s_brand_id:
                        try:
                            cursor.callproc('sp_add_store_with_brand',
                                            (s_mall_id, s_name, s_sqm, s_floor, s_is_open, s_brand_id))
                            conn.commit()
                            st.success("Store added & mapped to brand!")
                        except Error as e:
                            st.error(f"Error: {e.msg}")

        cursor.close()
        conn.close()

elif choice == "Employee Management":
    st.title("Employee Management")

    conn = get_connection()
    if conn:
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT emp_type_id, emp_type_name FROM employee_types")
        types_data = cursor.fetchall()
        type_options = {t['emp_type_name']: t['emp_type_id'] for t in types_data}

        st.subheader("Hire New Employee")
        with st.form("hire_employee_form", clear_on_submit=True):
            st.markdown("**Personal Details**")
            col1, col2 = st.columns(2)
            tc_id = col1.text_input("TC Identity Number", max_chars=11)
            first_name = col1.text_input("First Name")
            last_name = col2.text_input("Last Name")
            phone = col2.text_input("Phone Number")

            st.markdown("**Job Details**")
            col3, col4 = st.columns(2)
            department_id = col3.number_input("Department ID", min_value=1, step=1)
            store_id = col3.number_input("Assigned Store ID", min_value=1, step=1)
            salary = col4.number_input("Salary (₺)", min_value=0.0, step=100.0)

            if type_options:
                selected_type_label = col4.selectbox("Employee Type", list(type_options.keys()))
                type_id = type_options[selected_type_label]
            else:
                col4.warning("No employee types found in DB!")
                type_id = 1

            st.markdown("**Full Address Details**")
            col5, col6 = st.columns(2)
            city = col5.text_input("City")
            district = col6.text_input("District")
            street = col5.text_input("Street / Avenue")
            apartment_no = col6.text_input("Apartment / Door No")

            if st.form_submit_button("Hire Employee"):
                try:
                    cursor.callproc('sp_hire_new_employee',
                                    (tc_id, first_name, last_name, department_id, type_id, store_id, salary, phone,
                                     city, district, street, apartment_no))
                    conn.commit()
                    st.success(f"Employee {first_name} {last_name} hired successfully!")
                except Error as e:
                    st.error(f"Database Error: {e.msg}")

        cursor.close()
        conn.close()

elif choice == "Reports":
    st.title("System Reports")

    conn = get_connection()
    if conn:
        cursor = conn.cursor(dictionary=True)

        tab1, tab2, tab3 = st.tabs(["All Employees", "Department Stats", "Store Directory"])

        with tab1:
            st.subheader("Active Employee Directory")
            cursor.execute("SELECT * FROM view_active_employee_directory")
            emps = cursor.fetchall()
            if emps:
                st.dataframe(pd.DataFrame(emps), use_container_width=True)
            else:
                st.info("No records found.")

        with tab2:
            st.subheader("Department Employee Count")
            cursor.execute("SELECT * FROM view_department_stats")
            dept_stats = cursor.fetchall()
            if dept_stats:
                st.dataframe(pd.DataFrame(dept_stats), use_container_width=True)
            else:
                st.info("No records found.")

        with tab3:
            st.subheader("Full Store List")
            cursor.execute("SELECT * FROM view_all_stores")
            stores_list = cursor.fetchall()
            if stores_list:
                st.dataframe(pd.DataFrame(stores_list), use_container_width=True)
            else:
                st.info("No records found.")

        cursor.close()
        conn.close()