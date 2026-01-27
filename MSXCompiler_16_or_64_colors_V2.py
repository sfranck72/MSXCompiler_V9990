# streamlit run C:\Users\7212188K\PycharmProjects\Streamlit\MSXCompiler_16_or_64_colors_V2.py
# -> bmp 16 and 64 colors if indexed in ASEPRITE

import math
import struct
import streamlit as st
import io


# ====================================================================================================
# FONCTIONS
# ====================================================================================================

def rgb0_to_bgr(lst):
    result = []
    # Process list in steps of 4
    for i in range(0, len(lst), 4):
        group = lst[i:i + 4]

        # Only process full groups of 4
        if len(group) == 4:
            a, b, c, d = group  # unpack
            result.extend([c, b, a])  # swap a & c, remove d
    return result


def flip_from_bytes(data_bytes):
    """
    Retourne un bytearray de l'image BMP retournée verticalement.
    Gère le 8-bit (64 col) et le 4-bit (16 col).
    """
    data = bytearray(data_bytes)

    # --- BMP HEADER PARSING ---
    pixel_offset = int.from_bytes(data[10:14], "little")
    width = int.from_bytes(data[18:22], "little")
    bits_per_pixel = int.from_bytes(data[28:30], "little")
    compression = int.from_bytes(data[30:34], "little")

    if bits_per_pixel not in [4, 8]:
        raise ValueError("This function only supports 4-bit or 8-bit BMP images.")
    if compression != 0:
        raise ValueError("Only uncompressed BMPs (BI_RGB) are supported.")

    # --- ROW SIZE WITH PADDING (4-byte alignment) ---
    if bits_per_pixel == 8:
        # 1 pixel = 1 byte
        row_size = (width + 3) & ~3
    else:
        # 4-bit: 2 pixels = 1 byte.
        # Calculate width in bytes first (rounding up)
        width_in_bytes = (width + 1) // 2
        row_size = (width_in_bytes + 3) & ~3

    # Pointer to pixel data
    px = data[pixel_offset:]

    # --- SPLIT INTO ROWS ---
    # Safety check to avoid index out of range if file is slightly malformed
    rows = []
    for i in range(0, len(px), row_size):
        chunk = px[i:i + row_size]
        if len(chunk) == row_size:
            rows.append(chunk)

    # --- FLIP VERTICALLY ---
    rows.reverse()

    # --- WRITE BACK INTO BYTEARRAY ---
    flipped = bytearray()
    for r in rows:
        flipped.extend(r)

    # Return a full BMP as bytearray (header + flipped pixel data)
    return data[:pixel_offset] + flipped


# ====================================================================================================
# CONFIGURATION PAGE
# ====================================================================================================

st.set_page_config(page_title="64 colors Splitter", page_icon=":sunglasses:")

# TITRE (Ne pas toucher)
st.title('[V9990] bmp -> B1 16 or 64 colors', anchor=None)
st.title('-> Display colors & split binaries', anchor=None)
st.header(':blue[for MSXCompiler] :sunglasses:', anchor=None)
st.info('Split logic: 13500 bytes + Remainder. Checks file integrity before saving.')

# LOAD IMAGE BMP
image_download = st.file_uploader("Upload your image", accept_multiple_files=False, type=["bmp"])

if image_download is not None:
    st.image(image_download)
    raw_bytes = image_download.getvalue()
    data = bytearray(raw_bytes)

    # Variables de détection
    is_16_colors = False
    nb_colors_display = 0

    # AFFICHAGE DES INFOS DU BMP
    try:
        type_bmp, size, reserved1, reserved2, off_set = struct.unpack_from('<2sI2s2sI', data)
        # Lecture du nombre de bits par pixel (offset 28)
        bits_per_pixel = int.from_bytes(data[28:30], "little")

        bmp_sig = type_bmp.decode('ascii')

        # Détection du mode
        mode_str = ""
        if bits_per_pixel == 4:
            mode_str = " (16 Colors / 4-bit)"
            is_16_colors = True
            nb_colors_display = 16
            st.success("Detected: 16 Colors BMP")
        elif bits_per_pixel == 8:
            mode_str = " (64/256 Colors / 8-bit)"
            is_16_colors = False
            nb_colors_display = 64  # On garde 64 comme dans ton script original pour le mode 8-bit
            st.success("Detected: 64 Colors BMP")
        else:
            st.error(f"Error: Unsupported bit depth {bits_per_pixel}. Use 4-bit or 8-bit.")
            st.stop()

        final = f"Type= {bmp_sig} || Taille= {size} octets || Offset image= {off_set} octets || BPP= {bits_per_pixel}{mode_str}"
        st.text(final)
    except Exception as e:
        st.error(f"Erreur de lecture du header BMP: {e}")

    st.divider()

    # LES COULEURS
    off_set_color = struct.unpack_from('H', data, offset=14)
    off_set_colors = off_set_color[0] + 14

    # Adaptation de la lecture de la palette selon le mode
    # Chaque couleur = 4 octets (B, G, R, Reserved)
    if is_16_colors:
        bytes_to_read = 16 * 4  # 64 octets pour 16 couleurs
    else:
        bytes_to_read = 64 * 4  # 256 octets pour 64 couleurs (comme script original)

    col = struct.unpack_from(f'{bytes_to_read}B', data, offset=off_set_colors)
    couleurs = list(col)

    # Conversion vers espace 32768 couleurs (0-31)
    for i in range(0, len(couleurs)):
        couleurs[i] = math.floor(couleurs[i] / 8)

    reordered_colors = rgb0_to_bgr(couleurs)

    with st.expander('Colors'):
        st.badge(f'List of the {nb_colors_display} colors :')
        st.text(reordered_colors)

    # TRANSFORME ET DECOUPE
    with st.expander('Transform & Split Files'):
        nb_octets_pixels = len(data) - off_set
        SCREEN_SIZE = 27136

        # On affiche une estimation
        nb_screens_estim = nb_octets_pixels // SCREEN_SIZE
        st.text(f"Estimated screens = {nb_screens_estim}")

        name = st.text_input('Enter a base name (ex: file)', width=400)

        if name != "":
            if st.button(':floppy_disk: Start Backup'):
                try:
                    # 1. INVERSER L'IMAGE (FLIP)
                    flipped_data = flip_from_bytes(raw_bytes)

                    # 2. SUPPRIMER L'ENTETE DU BMP
                    del flipped_data[:off_set]

                    # --- VERIFICATION DE SECURITE ---
                    total_data_size = len(flipped_data)
                    remainder = total_data_size % SCREEN_SIZE

                    if remainder != 0:
                        st.error(
                            f"⛔ ERREUR CRITIQUE : La taille des données ({total_data_size} octets) n'est pas un multiple de {SCREEN_SIZE}.")
                        st.error(
                            f"Il y a {remainder} octets en trop ou en moins. Vérifiez la taille de votre BMP (doit être un multiple de 256x212 pixels).")
                        st.stop()  # Arrête l'exécution ici

                    # Si on passe ici, la taille est parfaite
                    nb_screens = total_data_size // SCREEN_SIZE
                    st.success(f"✅ Taille valide : {total_data_size} octets ({nb_screens} écrans complets).")

                    # 3. BOUCLE DE SAUVEGARDE (Inchangée)
                    CHUNK_LIMIT = 13500
                    file_counter = 1

                    for i in range(nb_screens):
                        # Extraire les 27136 octets de l'écran courant
                        start_idx = i * SCREEN_SIZE
                        end_idx = start_idx + SCREEN_SIZE
                        screen_pixels = flipped_data[start_idx:end_idx]

                        # --- DECOUPAGE ---
                        part1 = screen_pixels[:CHUNK_LIMIT]
                        part2 = screen_pixels[CHUNK_LIMIT:]

                        # --- SAUVEGARDE PARTIE 1 ---
                        filename1 = f"{name}{file_counter}.bin"
                        with open(filename1, 'wb') as f:
                            f.write(part1)
                        st.write(f"💾 Saved: {filename1} ({len(part1)} bytes)")

                        file_counter += 1

                        # --- SAUVEGARDE PARTIE 2 ---
                        if len(part2) > 0:
                            filename2 = f"{name}{file_counter}.bin"
                            with open(filename2, 'wb') as f:
                                f.write(part2)
                            st.write(f"💾 Saved: {filename2} ({len(part2)} bytes)")

                            file_counter += 1

                    st.success('Backup complete! Files are in the script directory.')

                except Exception as e:
                    st.error(f"Une erreur est survenue lors du traitement : {e}")