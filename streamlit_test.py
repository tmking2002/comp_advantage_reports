import pandas as pd
import streamlit as st

offensive_data = pd.read_csv('data/oregon/offensive_data.csv')
offensive_data['name'] = offensive_data['FirstName'] + ' ' + offensive_data['LastName']
offensive_data['XBH'] = offensive_data['x2B'] + offensive_data['x3B'] + offensive_data['HR']

st.title("University of Oregon Hitting Report")

image_html = f"""
<div style="display: flex; justify-content: center;">
    <img src="https://1000logos.net/wp-content/uploads/2021/07/Oregon-Ducks-logo.png" width="250"/>
</div>
"""

st.markdown(image_html, unsafe_allow_html=True)

st.markdown("---")

st.markdown("<h2 style='text-align: center;'>Game Stats (2023)</h2>", unsafe_allow_html=True)

game_stats = offensive_data[['name', 'pos', 'PA', 'AVG', 'OPS', 'H', 'XBH', 'HR', 'wRAA', 'wRAA_per_100_PA']].dropna(subset=['AVG'])
game_stats = game_stats.rename(columns={'name': 'Name', 'pos': 'Pos', 'PA': 'PA', 'AVG': 'AVG', 'OPS': 'OPS', 'H': 'H', 'HR': 'HR', 'wRAA': 'wRAA', 'wRAA_per_100_PA': 'wRAA/100 PA'})

st.dataframe(game_stats.set_index(game_stats.columns[0]))

st.markdown("---")

st.markdown("<h2 style='text-align: center;'>Sensor Testing Scores</h2>", unsafe_allow_html=True)

selected_test = st.selectbox("Select Test", ['Home to First', 'Home to Home', '5-10-5'])

if selected_test == 'Home to First':
    selected_data = offensive_data[['name', 'pos', 'H1']].dropna(subset=['H1']).rename(columns={'name': 'Name', 'pos': 'Pos', 'H1': 'Time (s)'}).set_index('Name').sort_values('Time (s)')
elif selected_test == 'Home to Home':
    selected_data = offensive_data[['name', 'pos', 'HH']].dropna(subset=['HH']).rename(columns={'name': 'Name', 'pos': 'Pos', 'HH': 'Time (s)'}).set_index('Name').sort_values('Time (s)')
elif selected_test == "5-10-5":
    selected_data = offensive_data[['name', 'pos', 'agility']].dropna(subset=['agility']).rename(columns={'name': 'Name', 'pos': 'Pos', 'agility': 'Time (s)'}).set_index('Name').sort_values('Time (s)')  

st.write(
    f'<style>div.stDataFrame table {{margin: 0 auto;}}</style>',
    unsafe_allow_html=True
)
st.dataframe(selected_data)