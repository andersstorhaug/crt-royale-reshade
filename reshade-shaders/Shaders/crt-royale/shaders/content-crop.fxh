#ifndef _CONTENT_CROPPING
#define _CONTENT_CROPPING

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale-reshade: A port of TroggleMonkey's crt-royale from libretro to ReShade.
//  Copyright (C) 2020 Alex Gunter <akg7634@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


#include "shared-objects.fxh"


// The normalized center is 0.5 plus the normalized offset
static const float2 content_center = (TEXCOORD_OFFSET + float2(CONTENT_CENTER_X_INTERNAL, CONTENT_CENTER_Y_INTERNAL)) / buffer_size + 0.5;
// The content's normalized diameter d is its size divided by the buffer's size. The radius is d/2.
static const float2 content_radius = content_size / (2.0 * buffer_size);

static const float content_left = content_center.x - content_radius.x;
static const float content_right = content_center.x + content_radius.x;
static const float content_upper = content_center.y - content_radius.y;
static const float content_lower = content_center.y + content_radius.y;

// The xy-offset of the top-left pixel in the content box
static const float2 content_offset = float2(content_left, content_upper);


void cropContentPixelShader(
    in const float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 texcoord_cropped = texcoord * content_size / buffer_size + content_offset;

#if VERTICAL_SCANLINES
    texcoord_cropped = ((texcoord_cropped - 0.5) * buffer_size).yx * (1.0 / buffer_size) + 0.5;
#endif

    color = tex2D(ReShade::BackBuffer, texcoord_cropped);
}

void uncropContentPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 texcoord_uncropped = (texcoord - content_offset) * buffer_size / content_size;

#if VERTICAL_SCANLINES
    texcoord_uncropped = ((texcoord_uncropped - 0.5) * content_size).yx * (1.0 / content_size) + 0.5;
#endif

    const bool is_in_boundary = all(step(texcoord_uncropped, 0) - step(texcoord_uncropped, 1));

    const float3 raw_color = tex2D(samplerGeometry, texcoord_uncropped).rgb;
    color = float4(is_in_boundary * raw_color, 1);
}

#endif  //  _CONTENT_CROPPING