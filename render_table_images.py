import os
from PIL import Image, ImageDraw, ImageFont

def get_font(name, size):
    fonts_dir = "C:/Windows/Fonts"
    font_paths = {
        "segoe": os.path.join(fonts_dir, "segoeui.ttf"),
        "segoe_bold": os.path.join(fonts_dir, "segoeuib.ttf"),
        "segoe_semi": os.path.join(fonts_dir, "seguisb.ttf"),
        "arial": os.path.join(fonts_dir, "arial.ttf"),
        "arial_bold": os.path.join(fonts_dir, "arialbd.ttf"),
        "consolas": os.path.join(fonts_dir, "consola.ttf"),
        "consolas_bold": os.path.join(fonts_dir, "consolab.ttf"),
    }
    path = font_paths.get(name)
    if path and os.path.exists(path):
        return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def wrap_text(draw, text, font, max_width):
    words = text.split(' ')
    lines = []
    current_line = []
    for word in words:
        test_line = ' '.join(current_line + [word])
        bbox = draw.textbbox((0, 0), test_line, font=font)
        w = bbox[2] - bbox[0]
        if w <= max_width:
            current_line.append(word)
        else:
            if current_line:
                lines.append(' '.join(current_line))
                current_line = [word]
            else:
                lines.append(word)
                current_line = []
    if current_line:
        lines.append(' '.join(current_line))
    return lines

def render_table(
    title,
    subtitle,
    headers,
    col_widths,
    rows,
    output_path=None,
    is_tracing=False
):
    pad_h = 24
    pad_v = 15
    margin = 36
    
    total_table_width = sum(col_widths)
    img_width = total_table_width + margin * 2
    
    # Fonts
    title_font = get_font("segoe_bold", 26)
    subtitle_font = get_font("segoe", 17)
    header_font = get_font("segoe_bold", 19)
    body_font = get_font("segoe", 17)
    code_font = get_font("consolas_bold", 17)
    pass_font = get_font("segoe_bold", 17)
    
    # Neutral Gray Palette (No Green Headers)
    header_bg = (55, 65, 81)       # #374151 - Clean Neutral Slate/Gray
    header_text_color = (255, 255, 255)
    row_bg_even = (255, 255, 255)
    row_bg_odd = (248, 250, 252)    # #F8FAFC
    border_color = (209, 213, 219)  # #D1D5DB
    text_color = (31, 41, 55)       # Charcoal text
    title_color = (31, 41, 55)
    subtitle_color = (100, 116, 139)
    code_color = (185, 28, 28)      # Burgundy/Red code identifier
    pass_color = (31, 41, 55)       # Neutral dark charcoal for clean default Pass text

    dummy_img = Image.new("RGB", (100, 100))
    draw = ImageDraw.Draw(dummy_img)

    row_heights = []
    wrapped_rows = []
    line_height = 25
    header_height = 52

    for row_data in rows:
        max_lines_in_row = 1
        wrapped_cells = []
        for col_idx, cell_text in enumerate(row_data):
            c_width = col_widths[col_idx] - pad_h * 2
            f = code_font if (is_tracing and col_idx == 1) else body_font
            lines = wrap_text(draw, cell_text, f, c_width)
            wrapped_cells.append(lines)
            if len(lines) > max_lines_in_row:
                max_lines_in_row = len(lines)
        wrapped_rows.append(wrapped_cells)
        r_height = max(48, pad_v * 2 + max_lines_in_row * line_height)
        row_heights.append(r_height)

    title_area_height = 90
    table_total_height = header_height + sum(row_heights)
    img_height = margin + title_area_height + table_total_height + margin

    img = Image.new("RGB", (img_width, img_height), (255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Title & Subtitle
    draw.text((margin, margin + 2), title, fill=title_color, font=title_font)
    draw.text((margin, margin + 40), subtitle, fill=subtitle_color, font=subtitle_font)

    start_x = margin
    start_y = margin + title_area_height

    # 1. Header row
    curr_x = start_x
    for col_idx, h_text in enumerate(headers):
        c_w = col_widths[col_idx]
        draw.rectangle([curr_x, start_y, curr_x + c_w, start_y + header_height], fill=header_bg)
        draw.rectangle([curr_x, start_y, curr_x + c_w, start_y + header_height], outline=border_color, width=1)
        
        bbox = draw.textbbox((0, 0), h_text, font=header_font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        
        if col_idx == 2 and not is_tracing:
            tx = curr_x + (c_w - tw) // 2
        else:
            tx = curr_x + pad_h
        ty = start_y + (header_height - th) // 2 - 2
        draw.text((tx, ty), h_text, fill=header_text_color, font=header_font)
        curr_x += c_w

    # 2. Body rows
    curr_y = start_y + header_height
    for row_idx, wrapped_cells in enumerate(wrapped_rows):
        r_h = row_heights[row_idx]
        bg_col = row_bg_odd if row_idx % 2 == 1 else row_bg_even
        curr_x = start_x

        for col_idx, lines in enumerate(wrapped_cells):
            c_w = col_widths[col_idx]
            draw.rectangle([curr_x, curr_y, curr_x + c_w, curr_y + r_h], fill=bg_col)
            draw.rectangle([curr_x, curr_y, curr_x + c_w, curr_y + r_h], outline=border_color, width=1)

            if not is_tracing and col_idx == 2:
                f = pass_font
                c = pass_color
                for l_idx, line in enumerate(lines):
                    bbox = draw.textbbox((0, 0), line, font=f)
                    tw = bbox[2] - bbox[0]
                    tx = curr_x + (c_w - tw) // 2
                    ty = curr_y + (r_h - len(lines) * line_height) // 2 + l_idx * line_height
                    draw.text((tx, ty), line, fill=c, font=f)
            else:
                if is_tracing and col_idx == 1:
                    f = code_font
                    c = code_color
                else:
                    f = body_font
                    c = text_color
                
                content_h = len(lines) * line_height
                ty = curr_y + (r_h - content_h) // 2
                for l_idx, line in enumerate(lines):
                    draw.text((curr_x + pad_h, ty + l_idx * line_height), line, fill=c, font=f)

            curr_x += c_w
        curr_y += r_h

    draw.rectangle([start_x, start_y, start_x + total_table_width, curr_y], outline=border_color, width=2)

    if output_path:
        img.save(output_path, "PNG", quality=95)
        print(f"Saved: {output_path}")

    return img

def main():
    testing_headers = ["Test", "Expected Result", "Pass/Fail"]
    testing_widths = [450, 680, 150]
    testing_rows = [
        ["Log in using the default admin account.", "MainScreen opens.", "Pass"],
        ["Open Social Media.", "Sample posts appear.", "Pass"],
        ["Submit a post with empty fields.", "Validation message appears.", "Pass"],
        ["Submit a post with an invalid URL.", "URL validation message appears.", "Pass"],
        ["Submit a valid post.", "New post appears at the top with the logged-in username.", "Pass"],
        ["Tap Like twice.", "Changes to Liked, then back to Like.", "Pass"],
        ["Add a nonempty comment.", "Comment appears and count increases.", "Pass"],
        ["Submit a blank comment.", "No comment is added.", "Pass"],
        ["Like a sample post, then create another post.", "The original post keeps its liked state.", "Pass"],
        ["Switch to Home and return.", "Posts, likes, and comments remain.", "Pass"],
        ["Log out, register, and log in with a new account.", "New posts use the registered username.", "Pass"],
    ]

    tracing_headers = ["Action", "Method or Statement", "What Happens?"]
    tracing_widths = [260, 340, 680]
    tracing_rows = [
        [
            "Successful login",
            "DemoAuth.login()",
            "Validates user credentials against admin/admin123 or registered credentials. If valid, assigns DemoAuth.currentUsername to the authenticated username and returns true, allowing navigation to MainScreen."
        ],
        [
            "Tap the + button",
            "openCreatePostSheet()",
            "Opens a modal bottom sheet displaying CreatePostSheet via showModalBottomSheet<Post>(), passing widget.username and awaiting the created Post asynchronously."
        ],
        [
            "Submit a valid post",
            "Navigator.pop(context, newPost)",
            "Validates non-empty fields and HTTP/HTTPS image URL schema, instantiates the Post object with widget.username, closes the sheet, and returns newPost to openCreatePostSheet()."
        ],
        [
            "Receive the new post",
            "posts.insert(0, newPost)",
            "Inserts the returned Post at index 0 of the posts list inside setState(), triggering a rebuild so the new post appears immediately at the top of the feed."
        ],
        [
            "Tap Like",
            "isLiked = !isLiked",
            "Toggles the boolean isLiked state inside setState(), updating the heart icon between favorite and favorite_border and the button label between Liked and Like."
        ],
        [
            "Send a comment",
            "comments.add(comment)",
            "Appends the trimmed, non-empty comment string to the comments list inside setState(), clears commentController, increments the comment counter, and renders the comment bubble."
        ]
    ]

    img_testing = render_table(
        title="Step 11: Application Testing Table",
        subtitle="Completed verification tests based on actual application behavior",
        headers=testing_headers,
        col_widths=testing_widths,
        rows=testing_rows,
        output_path="application_testing_table.png",
        is_tracing=False
    )
    img_testing.save("screenshots/application_testing_table.png", "PNG", quality=95)

    img_tracing = render_table(
        title="Step 12: Code Tracing Table",
        subtitle="Detailed execution flow and runtime behavior for each key action",
        headers=tracing_headers,
        col_widths=tracing_widths,
        rows=tracing_rows,
        output_path="code_tracing_table.png",
        is_tracing=True
    )
    img_tracing.save("screenshots/code_tracing_table.png", "PNG", quality=95)

    # Combined stacked image
    gap = 40
    comb_w = max(img_testing.width, img_tracing.width)
    comb_h = img_testing.height + img_tracing.height + gap
    comb_img = Image.new("RGB", (comb_w, comb_h), (255, 255, 255))
    comb_img.paste(img_testing, (0, 0))
    comb_img.paste(img_tracing, (0, img_testing.height + gap))
    
    comb_img.save("testing_and_tracing_tables.png", "PNG", quality=95)
    comb_img.save("screenshots/testing_and_tracing_tables.png", "PNG", quality=95)
    print("Saved combined tables to testing_and_tracing_tables.png and screenshots/testing_and_tracing_tables.png")

if __name__ == "__main__":
    main()
